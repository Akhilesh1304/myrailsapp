module HlsVideos
  class SubtitlesProcessingStatusService < BaseService
    attr_accessor :course_id

    def initialize(course_id)
      @course_id = course_id
    end

    def call
      {
        total: jobs.size,
        completed: {
          count: completed_jobs.size,
          jobs: completed_jobs
        },
        failed: {
          count: failed_jobs.size,
          jobs: failed_jobs
        },
        processing: {
          count: processing_jobs.size,
          jobs: processing_jobs
        }
      }
    end

    private

    def completed_jobs
      @completed_jobs ||= jobs.select { |j| [Constants::HlsVideosMeta::STATUS_COMPLETE].include?(j.status) }
    end

    def failed_jobs
      @failed_jobs ||= jobs.select do |j|
        [Constants::HlsVideosMeta::STATUS_TRANSCODING_FAILED,
         Constants::HlsVideosMeta::STATUS_POST_PROCESSING_FAILED].include?(j.status)
      end
    end

    def processing_jobs
      @processing_jobs ||= jobs.select do |j|
        [Constants::HlsVideosMeta::STATUS_INITIALIZED, Constants::HlsVideosMeta::STATUS_TRANSCODING,
         Constants::HlsVideosMeta::STATUS_POST_PROCESSING,
         Constants::HlsVideosMeta::STATUS_TRANSCODED].include?(j.status)
      end
    end

    def jobs
      @jobs ||= HlsVideoAiSrtJob
                .joins(:hls_videos_meta)
                .where(course_id:, active: true)
                .select('hls_videos_meta.status',
                        'hls_video_ai_srt_jobs.olympus_token',
                        'hls_video_ai_srt_jobs.ref_olympus_token')
    end
  end
end
