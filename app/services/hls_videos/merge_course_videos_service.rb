module HlsVideos
  class MergeCourseVideosService < BaseService
    attr_accessor :course_id

    def initialize(course_id)
      @course_id = course_id
    end

    def call
      if incomplete?
        return { ok: false,
                 message: 'There are still few videos for which hls processing is in progress ' }
      end
      return { ok: false, message: 'Merging has already started' } if merge_started?

      start_merging
      jobs.each do |job|
        delay(queue: 'hls_video').process(job.id)
      end
      { ok: true, message: 'Merging has started' }
    end

    private

    def process(id)
      job = HlsVideoAiSrtJob.find id

      content_id = LmsContentInfo.where(context_id: course_id).hls_video_item
                                 .where("content_aux_details->>'olympus_token' = ?", job.olympus_token)
                                 .pluck(:content_id).first
      body, page_url = Lms::WikiPage.where(id: content_id).pluck(:body, :url).first
      body.gsub!(job.olympus_token, job.ref_olympus_token)
      lms_client.update_page(course_id, page_url, body)
      job.update!(workflow_state: Constants::HlsVideoAiSrtJob::STATUS_MERGED)
    end

    def start_merging
      HlsVideoAiSrtJob.where(id: jobs.map(&:id))
                      .update_all(workflow_state: Constants::HlsVideoAiSrtJob::STATUS_MERGED_STARTED)
    end

    def incomplete?
      jobs.reject { |j| j.status == Constants::HlsVideosMeta::STATUS_COMPLETE }.size.positive?
    end

    def merge_started?
      jobs.reject { |j| j.workflow_state == Constants::HlsVideoAiSrtJob::STATUS_STARTED }.size.positive?
    end

    def jobs
      @jobs ||= HlsVideoAiSrtJob
                .joins(:hls_videos_meta)
                .where(course_id:, active: true)
                .select('hls_videos_meta.status',
                        'hls_video_ai_srt_jobs.olympus_token',
                        'hls_video_ai_srt_jobs.ref_olympus_token',
                        'hls_video_ai_srt_jobs.workflow_state',
                        'hls_video_ai_srt_jobs.id')
    end

    def lms_client
      @lms_client ||= Lms::Client.new
    end
  end
end
# HlsVideos::MergeCourseVideosService.call(17_856)
