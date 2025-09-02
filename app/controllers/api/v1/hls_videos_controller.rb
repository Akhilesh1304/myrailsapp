module Api
  module V1
    class HlsVideosController < Api::BaseController
      skip_before_action :verify_authenticity_token
      skip_before_action :enrolled_user!

      def generate_course_subtitles
        in_progress = HlsVideoAiSrtJob.where(course_id: @course_id, active: true).exists?
        return render json: { error: 'Already processing of course is initiated' }, status: :bad_request if in_progress

        HlsVideos::AiSubtitlesVideoProcessingService.call(@course_id, true, @current_user_id)
        render json: { ok: true }
      end

      def subtitles_processing_status
        data = HlsVideos::SubtitlesProcessingStatusService.call(@course_id)
        render json: data
      end

      def merge_videos
        data = HlsVideos::MergeCourseVideosService.call(@course_id)
        render json: data, status: data[:ok] ? 200 : 400
      end
    end
  end
end
