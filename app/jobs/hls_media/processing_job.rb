module HlsMedia
  class ProcessingJob < ApplicationJob
    queue_as :hls_video_processing_queue

    def perform(video_meta_id)
      video_meta = HlsVideosMeta.find_by(id: video_meta_id)

      return if video_meta.blank?

      if video_meta.status != Constants::HlsVideosMeta::STATUS_INITIALIZED
        Delayed::Worker.logger.info("HlsVideoProcessingJob:: Skipping processing of file
        : #{video_meta.key}, Video meta ID: #{video_meta.id}")
        return
      end

      HlsVideos::CreateHlsJobService.new(video_meta_id).call

      Delayed::Worker.logger.info("HlsMedia::ProcessJob
      Processing file : #{video_meta.key}, Video meta ID: #{video_meta.id}")
    end
  end
end
