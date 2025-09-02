class MetabaseDashboard < ActiveRecord::Base
  scope :active, -> { where(status: 'active') }
  scope :dashboard_type, -> { where(dashboard_type: 'quicksight_dashboard') }

  def self.get_dashboard(dashboard_id)
    active.select(:name, :url, :access_roles).find_by(dashboard_id:)
  end

  def self.list_dashboards(user_id, user_current_roles)
    all_dashboards = active.dashboard_type.order(order: :desc).select(:dashboard_id, :name, :access_roles, :description)

    accessible_dashboards = []
    is_ops_head = Program.exists?(ops_mgr_id: user_id)
    user_current_roles += Constants::Lms::Role::OPS_HEAD_ROLE if is_ops_head

    is_bu_head = Program.exists?(bu_head_id: user_id)
    user_current_roles += Constants::Lms::Role::BU_HEAD_ROLE if is_bu_head
    Rails.logger.info("User roles: #{user_current_roles}")
    all_dashboards.each do |dashboard|
      Rails.logger.info("Access roles: #{dashboard.access_roles}")
      valid_roles = dashboard.access_roles & user_current_roles
      unless valid_roles.empty?
        accessible_dashboards << { dashboard_id: dashboard.dashboard_id, name: dashboard.name,
                                   description: dashboard.description }
      end
    end

    accessible_dashboards
  end
end
