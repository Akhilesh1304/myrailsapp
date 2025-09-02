module HlsVideos
  class PostProcessingService
    attr_reader :video_meta_id

    def initialize(video_meta_id:)
      @video_meta_id = video_meta_id
    end

    def call
      video_meta = HlsVideosMeta.find(video_meta_id)
      job_id = video_meta.job_id

      unless ready_for_post_processing?(video_meta)
        Rails.logger.info "Skipping post processing for job: #{job_id}"
        return
      end

      Rails.logger.info "Post processing for job: #{job_id}"

      process_and_assign_output_download_key(video_meta, job_id)
      deactivate_existing_video_metas(video_meta)
      complete_video_meta(video_meta)
    end

    private

    def s3_client
      @s3_client ||= Aws::S3::Client.new(region: Settings.aws_region)
    end

    def ready_for_post_processing?(video_meta)
      video_meta.status == Constants::HlsVideosMeta::STATUS_POST_PROCESSING
    end

    def process_and_assign_output_download_key(video_meta, job_id)
      output_download_key = video_meta.output_download_key
      return unless output_download_key.present?

      Rails.logger.info "Processing output download key for job: #{job_id}, key: #{output_download_key}"

      download_key_data = process_output_download_key(output_download_key)
      video_meta.download_key = download_key_data[:download_key]
      video_meta.download_key_size = download_key_data[:content_length]

      Rails.logger.info "Processed output download key for job: #{job_id}, key: #{output_download_key}"
    end

    def process_output_download_key(output_download_key)
      client = s3_client

      src_download_key = "#{HlsVideosMeta.video_output_key_prefix}#{output_download_key}"
      dest_download_key = "#{HlsVideosMeta.download_key_prefix}#{output_download_key}"

      params = {
        bucket: Settings.hls_videos_bucket,
        copy_source: "/#{Settings.hls_videos_bucket}/#{src_download_key}",
        key: dest_download_key
      }
      client.copy_object(params)

      resp = client.list_objects({ bucket: Settings.hls_videos_bucket, prefix: dest_download_key })
      item = resp.contents.first

      { download_key: item.key, content_length: item.size }
    end

    def deactivate_existing_video_metas(video_meta)
      existing_video_metas = HlsVideosMeta.where(olympus_token: video_meta.olympus_token, active: true)
      @update_wiki_pages_info = false
      @is_video_duration_updated = false

      ActiveRecord::Base.transaction do
        existing_video_metas.each do |existing_video_meta|
          existing_video_meta.active = false
          existing_video_meta.save!
          old_duration = existing_video_meta.video_duration
          @is_video_duration_updated = ([old_duration + 1, old_duration,
                                         old_duration - 1].exclude? video_meta.video_duration)
          @update_wiki_pages_info = true
        end
      end
    end

    def complete_video_meta(video_meta)
      ActiveRecord::Base.transaction do
        video_meta.status = Constants::HlsVideosMeta::STATUS_COMPLETE
        video_meta.active = true
        video_meta.processed_at = Time.current
        video_meta.save!

        if @update_wiki_pages_info
          HlsVideos::UpdateLmsContentInfoService.new(
            video_meta_id: video_meta.id,
            is_video_duration_updated: @is_video_duration_updated
          ).delay(queue: 'hls_video_processing_queue').call

        end
      end

      Rails.logger.info "Completed job: #{video_meta.job_id}"
    end
  end
end
