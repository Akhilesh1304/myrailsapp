module HlsVideos
  class UpdateMetaDetailsService
    attr_reader :video_meta_ids

    def initialize(video_meta_ids = [])
      @video_meta_ids = video_meta_ids
    end

    def call
      details = {}
      video_metas = fetch_video_metas

      video_metas.each do |video_meta|
        job = fetch_job(video_meta)

        if video_meta.status == Constants::HlsVideosMeta::STATUS_TRANSCODING
          video_status = process_transcoding(video_meta, job)
          update_video_meta_status(video_meta, video_status)
        end

        post_process_video_meta(video_meta) if video_meta.status == Constants::HlsVideosMeta::STATUS_TRANSCODED

        Rails.logger.info "Updated details for media: #{video_meta.key}, olympus_token: #{video_meta.olympus_token}"

        details[video_meta.id] = { status: video_meta.status }
      end

      details
    end

    private

    def mediaconvert
      @mediaconvert ||= Aws::MediaConvert::Client.new(region: 'us-east-1')
    end

    def fetch_video_metas
      if video_meta_ids.present?
        HlsVideosMeta.where(id: video_meta_ids)
      else
        HlsVideosMeta.where(status: [Constants::HlsVideosMeta::STATUS_TRANSCODING,
                                     Constants::HlsVideosMeta::STATUS_TRANSCODED],
                            file_type: 'f')
                     .where(HlsVideosMeta.arel_table[:created_at].gt(1.day.ago))
      end
    end

    def fetch_job(video_meta)
      mediaconvert.get_job(id: video_meta.job_id).job
    end

    def process_transcoding(video_meta, job)
      video_status = nil

      if job.status == 'COMPLETE'
        video_status = Constants::HlsVideosMeta::STATUS_TRANSCODED
        video_duration = extract_video_duration(job)
        video_meta.video_duration = video_duration if video_duration.present?
      elsif job.status == 'ERROR'
        video_status = Constants::HlsVideosMeta::STATUS_TRANSCODING_FAILED
      end

      video_status
    end

    def extract_video_duration(job)
      duration_in_ms = job.output_group_details[0].output_details[0].duration_in_ms

      (duration_in_ms / 1000.0).to_i
    end

    def update_video_meta_status(video_meta, video_status)
      return unless video_status.present?

      video_meta.status = video_status
      video_meta.save!

      Rails.logger.info "Transcoding job: #{video_meta.job_id}, key: #{video_meta.key}, updated status: #{video_status}"
    end

    def post_process_video_meta(video_meta)
      ActiveRecord::Base.transaction do
        video_meta.status = Constants::HlsVideosMeta::STATUS_POST_PROCESSING
        if video_meta.parent.blank?
          tree_data = video_meta.parse_and_create_directories
          video_meta.name = tree_data[:name]
          video_meta.parent = tree_data[:parent]
        end
        video_meta.save!

        HlsVideos::PostProcessingService.new(video_meta_id: video_meta.id)
                                        .delay(queue: 'hls_video_processing_queue').call
      end

      Rails.logger.info("Enqueued permissions job: #{video_meta.job_id},
      key: #{video_meta.key}, updated status: #{video_meta.status}")
    end
  end
end
