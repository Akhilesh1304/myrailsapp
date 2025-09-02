module HlsVideos
  class ProcessVideoService
    attr_reader :file_path, :re_process, :processed_by, :create_new_video, :ai_srt

    def initialize(file_path:, re_process:, processed_by:, create_new_video: false, ai_srt: false)
      @file_path = file_path
      @re_process = re_process
      @processed_by = processed_by
      @create_new_video = create_new_video
      @ai_srt = ai_srt
    end

    def call
      video_details = HlsVideos::VideoCheckerService.new(
        file_path:,
        re_process:,
        create_new_video:,
        ai_srt:
      ).call

      process_media(video_details, processed_by)

      {
        status: 'success',
        videos_count: video_details[:videos_count],
        processing_videos: video_details[:processing_videos],
        skipped_videos: video_details[:skipped_videos]
      }
    end

    private

    def process_media(media_details, processed_by)
      processing_videos = media_details[:processing_videos]
      return unless processing_videos.present?

      ActiveRecord::Base.transaction do
        processing_videos.each do |processing_video|
          key = processing_video[:key]
          last_modified = processing_video[:last_modified]
          olympus_token = processing_video[:olympus_token]
          ai_srt = processing_video[:ai_srt]

          video_meta = HlsVideosMeta.new(
            key:,
            last_modified:,
            active: false,
            status: Constants::HlsVideosMeta::STATUS_INITIALIZED,
            processed_by:,
            ai_srt:
          )

          if olympus_token.present?
            video_meta.olympus_token = olympus_token
          else
            video_meta.set_olympus_token
          end

          video_meta.save!

          HlsMedia::ProcessingJob.perform_later(video_meta.id)

          processing_video[:id] = video_meta.id
          processing_video[:status] = Constants::HlsVideosMeta::STATUS_INITIALIZED
          processing_video[:olympus_token_used] = video_meta.olympus_token
        end
      end
    end
  end
end
