module Api
  module V1
    class MediaProcessingController < Api::BaseController
      skip_before_action :enrolled_user!
      skip_before_action :authorize_request!
      skip_before_action :verify_authenticity_token

      def process_video_internal_api
        process_video
      end

      def process_folder_internal_api
        process_folder
      end

      def media_status
        meta_ids = params[:meta_ids]

        meta_details = HlsVideosMeta.meta_details(meta_ids)

        response = {
          status: 'success',
          meta_details:
        }
        render json: { response: }
      end

      private

      def process_video
        file_path = params[:s3_video_path]
        only_check = param_true?(:only_check)
        re_process = param_true?(:reprocess_videos)
        create_new_video = param_true?(:create_new_video)
        ai_srt = param_true?(:ai_srt)

        process_response =
          if only_check
            HlsVideos::VideoCheckerService.new(file_path:, re_process:, create_new_video:, ai_srt:).call
          else
            HlsVideos::ProcessVideoService.new(file_path:,
                                               re_process:,
                                               processed_by: @current_user_id,
                                               create_new_video:,
                                               ai_srt:).call
          end

        response = {
          process_response:,
          only_check:
        }

        render json: { response: }
      end

      def process_folder
        path = params['s3_folder_path']
        path = "#{path}/" if path.present? && path[-1] != '/'

        only_check = param_true?('only_check')
        reprocess_videos = param_true?('reprocess_videos')

        process_response = if only_check
                             HlsVideos::FolderCheckerService.new(folder_path: path, re_process: reprocess_videos).call
                           else
                             HlsVideos::ProcessFolderService.new(folder_path: path, re_process: reprocess_videos,
                                                                 processed_by: @current_user_id).call
                           end

        response = {
          process_response:,
          only_check:
        }

        render json: { response: }
      end

      def param_true?(key)
        params[key].to_s == 'true'
      end
    end
  end
end
