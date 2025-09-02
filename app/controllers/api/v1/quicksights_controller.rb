module Api
  module V1
    class QuicksightsController < Api::BaseController
      # skip_before_action :verify_authenticity_token
      # skip_before_action :enrolled_user!

      def index
        dashboards = MetabaseDashboard.list_dashboards(@current_user_id, @current_role_names || [])
        render json: { dashboards: }
      end

      def show
        dashboard_id = params[:id]
        results = fetch_dashboard(dashboard_id)
        if results.nil?
          render json: { error: 'Dashboard not found' }, status: :forbidden
          return
        end

        results[:embed_url] = fetch_embed_url(dashboard_id)

        render json: results
      rescue StandardError => e
        Rails.logger.error "Error fetching dashboards: #{e.message}"
        render json: { error: "Error fetching dashboards: #{e.message}" }, status: :internal_server_error
      end

      private

      def fetch_dashboard(dashboard_id)
        AwsQuicksight::Dashboard.new(dashboard_id:, current_user_id: @current_user_id,
                                     current_role_names: @current_role_names || []).dashboard
      end

      def fetch_embed_url(dashboard_id)
        service = AwsQuicksight::EmbedUrlService.new(dashboard_id:)
        resp = service.generate_embed_url
        Rails.logger.info("Embed url response: #{resp}")
        if resp.present? && resp.status == 200 && resp.embed_url.present?
          resp.embed_url
        else
          Rails.logger.error("Error occurred while getting embed url for aws quicksights: #{resp}")
          nil
        end
      end
    end
  end
end
