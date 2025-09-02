module HlsVideos
  class VideoCheckerService
    attr_reader :file_path, :re_process, :create_new_video, :ai_srt

    def initialize(file_path:, re_process: false, create_new_video: false, ai_srt: false)
      @file_path = file_path
      @re_process = re_process
      @create_new_video = create_new_video
      @ai_srt = ai_srt
      reset_state
    end

    def call
      return fail_with('Please provide a valid mp4 file') unless valid_mp4_path?

      begin
        contents = fetch_s3_contents
        if contents.empty?
          return fail_with('The specified file does not exist. Please provide a valid AWS S3 file path')
        end
        return fail_with('Please provide a valid AWS S3 file path') if contents.size > 1

        handle_single_content(contents.first)
      rescue StandardError => e
        Rails.logger.error "HlsVideos::VideoCheckerService error: #{e}, backtrace: #{e.backtrace}"
        fail_with('Unable to process the specified file. Please retry after some time')
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

    def valid_mp4_path?
      file_path.present? && file_path.ends_with?('.mp4')
    end

    def fetch_s3_contents
      s3_client.list_objects(bucket: Settings.hls_videos_bucket, prefix: file_path).contents
    end

    def s3_client
      @s3_client ||= Aws::S3::Client.new(region: 'us-east-1')
    end

    def fail_with(msg)
      @status = 'failure'
      @message = msg
      result_hash
    end

    def handle_single_content(item)
      return fail_with('Please provide a valid AWS S3 file path and ensure size is greater than 0') if item.empty?

      @videos_count += 1
      process_video, olympus_token, skipped_video_meta, message = determine_video_processing(item.key,
                                                                                             item.last_modified)

      if process_video
        @message = 'Specified file processing started'
        @processing_videos << processing_video_hash(item, olympus_token)
      else
        @status = 'failure'
        @skipped_videos << skipped_video_hash(item, skipped_video_meta)
        @message ||= message
      end
    end

    def processing_video_hash(item, olympus_token)
      {
        key: file_path,
        last_modified: item.last_modified,
        olympus_token:,
        caption_paths: VideoProcessor::CaptionFilesService.new(file_path, ai_srt).call,
        ai_srt:
      }
    end

    def skipped_video_hash(item, skipped_video_meta)
      {
        key: skipped_video_meta&.key,
        last_modified: item.last_modified,
        id: skipped_video_meta&.id,
        status: skipped_video_meta&.status,
        caption_paths: VideoProcessor::CaptionFilesService.new(file_path, ai_srt).call,
        ai_srt:
      }
    end

    def determine_video_processing(key, last_modified)
      video_metas = HlsVideosMeta.where(key:).ai_srt_filter(ai_srt)
      return [true, nil, nil, nil] if video_metas.blank? || create_new_video

      active_video_meta, in_progress_video_meta, = classify_video_metas(video_metas)

      return handle_in_progress_video(in_progress_video_meta) if in_progress_video_meta.present?
      return handle_active_video(active_video_meta, last_modified) if active_video_meta.present?

      [true, nil, nil, nil]
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

    def handle_in_progress_video(in_progress_video_meta)
      [
        false,
        nil,
        in_progress_video_meta,
        'Specified file is already getting processed'
      ]
    end

    def handle_active_video(active_video_meta, last_modified)
      if last_modified != active_video_meta.last_modified || re_process
        [true, active_video_meta.olympus_token, nil, nil]
      else
        [
          false,
          nil,
          active_video_meta,
          'Not processing file as there is no change since last processing'
        ]
      end
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
