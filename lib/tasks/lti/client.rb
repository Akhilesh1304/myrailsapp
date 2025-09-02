module Lti
  class Client < Request
    attr_accessor :base_url, :api_token

    include Api::HlsVideos
    include Api::LearnerCall
    include Api::MentoredGroupSession
    include Api::MentoredSessionAttendance
    include Api::AssessmentSchedule
    include Api::HlsVideos
    include Api::ProgramGroupCourseTemplateMapping

    def initialize
      @base_url = Settings.lti_base_url
      @api_token = Settings.internal_apis_lti_token
    end

    private

    def request_url(path)
      "#{base_url}/#{path}"
    end

    def headers
      { 'X-Internal-Api-Token': api_token }
    end
  end
end
