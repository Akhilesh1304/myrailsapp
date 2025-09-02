module Api
  class BaseController < ApplicationController
    # include ApiAuthenticatable
    # include OtpSessionAuthenticatable
    include BaseControllerHelper

    # before_action :set_page_params
    before_action :set_current_user_id
    # before_action :set_current_roles
    before_action :set_program_group_id
    before_action :set_student_id
    before_action :set_app_name
    # before_action :set_is_masquerading

    # include ApiAuthorization

    private

    def read_lms_redis(key)
      begin
        lms_cache_value = LmsRedis.instance.read(key, raw: true)
        lms_cache_value = Oj.load(lms_cache_value)
      rescue StandardError => e
        logger.error "An error of type #{e.class} happened, message is #{e.message}"
        lms_cache_value = nil
      end

      lms_cache_value
    end

    def set_page_params
      params[:page] = params[:page].to_i.zero? ? 1 : params[:page].to_i
      params[:per_page] = params[:per_page].to_i.zero? ? Constants::PER_PAGE : params[:per_page].to_i
    end

    def render_not_found_response(message)
      render_response(message, 404)
    end

    def render_success_response(message)
      render_response(message, 200)
    end

    def render_error_response(message)
      render_response(message, 400)
    end

    def render_unauthorised_response(message)
      render_response(message, 403)
    end

    def render_unauthenticated_response(message)
      render_response(message, 401)
    end

    def render_response(message, code)
      render json: { message: }, status: code
    end

    def render_unprocessable_entity_response(message)
      render_response(message, 422)
    end

    def pagination_dict(collection)
      {
        total_count: collection.total_entries,
        current_page: collection.current_page,
        next_page: collection.next_page,
        prev_page: collection.previous_page,
        total_pages: collection.total_pages
      }
    end

    def serialize(collection, serializer, root = nil, context = {}, adapter = :json)
      ActiveModelSerializers::SerializableResource.new(
        collection,
        each_serializer: serializer,
        root:,
        context:,
        adapter:
      ).as_json
    end

    def render_collection(collection, options = {})
      render_args = { json: collection, meta: pagination_dict(collection) }.merge(options)
      render render_args
    end

    def set_current_user_id
      @current_user_id = params[:current_user_id]
    end

    def set_current_roles
      roles = Lms::AccountUser.get_roles(@current_user_id)
      @current_role_ids = roles.keys
      @current_role_names = roles.values
    end

    def set_program_group_id
      @program_group_id = params[:program_group_id]
    end

    def set_is_masquerading
      @is_masquerading = request.headers['Masquerading-Token'].present?
    end

    def set_student_id
      @student_id = params[:user_id]
    end

    def set_app_name
      @app_name = app_names[controller_name]
    end

    def bad_request
      render json: { error: 'Unable to process the request. Please check your input and try again.' },
             status: :bad_request
    end

    def digital_campus_admin?
      digital_campus_roles = Constants::Lms::Role::DIGITAL_CAMPUS_ROLES
      @current_role_names.present? && (digital_campus_roles & @current_role_names).present?
    end
  end
end
