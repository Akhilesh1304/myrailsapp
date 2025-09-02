module Lti
  module Api
    module HlsVideos
      def process_hls_video(payload)
        post('api/v1/media_processing_internal/hls/video', payload:)
      rescue RestClient::ExceptionWithResponse => e
        e.response
      end
    end
  end
end
