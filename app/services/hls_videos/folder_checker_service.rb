module HlsVideos
  class FolderCheckerService
    attr_accessor :folder_path, :re_process

    def initialize(folder_path:, re_process: false)
      @folder_path = folder_path
      @re_process = re_process
      reset_state
    end

    def call
      return fail_with('Please provide a valid AWS S3 folder to process') unless folder_path.present?

      begin
        s3_contents.each do |item|
          process_s3_item(item)
        end
      rescue StandardError => e
        Rails.logger.error "HlsVideos::FolderCheckerService error: #{e}, backtrace: #{e.backtrace}"
        return fail_with('Unable to process the specified folder. Please ensure the folder is valid')
      end

      result_hash
    end

    private

    def reset_state
      @status = 'success'
      @message = nil
      @videos_count = 0
      @skipped_videos = []
      @processing_videos = []
    end

    def s3_client
      @s3_client ||= Aws::S3::Client.new(region: 'us-east-1')
    end

    def s3_contents
      s3_client.list_objects(bucket: Settings.hls_videos_bucket, prefix: folder_path).contents
    end

    def process_s3_item(item)
      key = item.key
      last_modified = item.last_modified

      if item.empty?
        Rails.logger.info "Found folder: #{key} of size: #{item.size}"
        return
      end

      unless process_item(item)
        Rails.logger.info "Not processing file: #{key} of size: #{item.size}"
        return
      end

      Rails.logger.info "Processing file: #{key} of size: #{item.size}"
      @videos_count += 1

      process_video, olympus_token, skipped_video_meta = determine_video_processing(key, last_modified)

      if process_video
        @processing_videos << processing_video_hash(key, last_modified, olympus_token)
      else
        @skipped_videos << skipped_video_hash(skipped_video_meta, last_modified)
      end
    end

    # Stub for process_item, implement your logic here
    def process_item(item)
      # Example: Only process .mp4 files
      item.key.ends_with?('.mp4')
    end

    def determine_video_processing(key, last_modified)
      process_video = true
      olympus_token = nil
      skipped_video_meta = nil

      video_metas = HlsVideosMeta.where(key:).ai_srt_filter(false)
      if video_metas.present?
        active_video_meta, in_progress_video_meta, = classify_video_metas(video_metas)

        if in_progress_video_meta.present?
          process_video = false
          skipped_video_meta = in_progress_video_meta
        elsif active_video_meta.present?
          if last_modified != active_video_meta.last_modified || re_process
            olympus_token = active_video_meta.olympus_token
          else
            process_video = false
            skipped_video_meta = active_video_meta
          end
        end
      end

      [process_video, olympus_token, skipped_video_meta]
    end

    def classify_video_metas(video_metas)
      active_video_meta = nil
      in_progress_video_meta = nil
      failed_video_meta = nil

      video_metas.each do |video_meta|
        if video_meta.active
          active_video_meta = video_meta
        elsif [Constants::HlsVideosMeta::STATUS_TRANSCODING_FAILED,
               Constants::HlsVideosMeta::STATUS_POST_PROCESSING_FAILED].include?(video_meta.status)
          failed_video_meta = video_meta
        elsif video_meta.status != Constants::HlsVideosMeta::STATUS_COMPLETE
          in_progress_video_meta = video_meta
        end
      end

      [active_video_meta, in_progress_video_meta, failed_video_meta]
    end

    def processing_video_hash(key, last_modified, olympus_token)
      {
        key:,
        last_modified:,
        olympus_token:,
        caption_paths: VideoProcessor::CaptionFilesService.new(key, false).call
      }
    end

    def skipped_video_hash(skipped_video_meta, last_modified)
      {
        key: skipped_video_meta.key,
        last_modified:,
        id: skipped_video_meta.id,
        status: skipped_video_meta.status,
        caption_paths: VideoProcessor::CaptionFilesService.new(skipped_video_meta.key, false).call
      }
    end

    def fail_with(msg)
      @status = 'failure'
      @message = msg
      result_hash
    end

    def result_hash
      {
        status: @status,
        message: @message,
        videos_count: @videos_count,
        processing_videos: @processing_videos,
        skipped_videos: @skipped_videos
      }
    end
  end
end
