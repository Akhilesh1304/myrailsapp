module HlsVideos
  class AiSubtitlesVideoProcessingService < BaseService
    attr_accessor :course_id, :create_new_video, :current_user_id

    def initialize(course_id, create_new_video, current_user_id)
      @course_id = course_id
      @create_new_video = create_new_video
      @current_user_id = current_user_id
    end

    def call
      Rails.logger.info "course_id: #{course_id}, create_new_video: #{create_new_video}, " \
                        "current_user_id: #{current_user_id}"
      Rails.logger.info "videos found: #{lms_content_info.size}"
      lms_content_info.each do |info|
        token = info.content_aux_details && info.content_aux_details['olympus_token']
        Rails.logger.info "reprocessing for token: #{token}"
        delay(queue: 'hls_video').process_video(token) if token.present?
      end
    end

    private

    def lms_content_info
      @lms_content_info ||= LmsContentInfo.where(context_id: course_id).hls_video_item
    end

    def process_video(token)
      video = fetch_video(token)
      return if video.blank?

      res = lti_client.process_hls_video({ s3_video_path: video.key, ai_srt: true, create_new_video:,
                                           user_id: current_user_id })
      Rails.logger.info "response in process_video: #{token}: #{res}"
      new_video = res.dig('response', 'process_response', 'processing_videos')&.first
      fail 'Unable to process the video' if new_video.blank?

      HlsVideoAiSrtJob.create!({ olympus_token: new_video['olympus_token_used'],
                                 ref_olympus_token: video.olympus_token,
                                 workflow_state: Constants::HlsVideoAiSrtJob::STATUS_STARTED,
                                 course_id:, created_by: current_user_id })
    end

    def fetch_video(token)
      hls_video = HlsVideosMeta.is_video.active.where(olympus_token: token).first

      if hls_video.blank?
        Rails.logger.info "video not found for token: #{token}"
        return nil
      end

      return nil if hls_video.caption_prefixes.include?('en')

      hls_video
    end

    def lti_client
      @lti_client ||= Lti::Client.new
    end
  end
end
