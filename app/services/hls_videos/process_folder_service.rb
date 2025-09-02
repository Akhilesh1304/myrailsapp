module HlsVideos
  class ProcessFolderService
    attr_reader :folder_path, :re_process, :processed_by

    def initialize(folder_path:, re_process:, processed_by:)
      @folder_path = folder_path
      @re_process = re_process
      @processed_by = processed_by
    end

    def call
      video_details = HlsVideos::FolderCheckerService.new(folder_path:, re_process:).call

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
