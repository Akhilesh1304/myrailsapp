class Program < ActiveRecord::Base
  has_many :program_group_details
  has_many :course_templates

  DEGREE_TYPE = 'degree_program'.freeze
  SEMESTER_TYPE = 'semester_program'.freeze

  scope :join_grading_schemes,
        lambda {
          joins('INNER JOIN grading_schemes gs ON gs.id = programs.grading_scheme_id')
        }

  scope :is_active, -> { where(is_active: 'true') }
  scope :not_digital_campus_program, -> { where(digital_campus_program: 'false') }

  enum proctoring_type: { no_proctor: 0, video_and_screen: 1, video_record_and_screen: 2,
                          open_book_video_screen_record: 3 }

  serialize :settings

  def plagiarism_enabled?
    settings[:plagiarism_check_enabled].to_i == 1
  end

  def peer_review_enabled?
    settings[:peer_review_enabled].to_i == 1
  end

  def assessment_class_enabled?
    settings[:enable_assessment_class].to_i == 1
  end

  def max_allowed_extensions
    settings[:max_allowed_extensions] || 'no_limit'
  end

  def extension_request_deadline
    settings[:extension_request_deadline] || 'any_time'
  end

  def workflow_enabled?
    workflow_details = settings[:workflow_details]
    return false if workflow_details.blank?

    workflow_details[:workflow_definition_id].to_i.positive? &&
      workflow_details[:initial_workflow_step_id].to_i.positive?
  end

  def specialisation_program_id
    if program_type == Program::SEMESTER_TYPE
      DegreeProgramMapping.find_by(semester_program_id: id)&.degree_program_id
    else
      id
    end
  end

  def semester_program?
    program_type == SEMESTER_TYPE
  end

  def gpa_based?
    GradingScheme.where(id: grading_scheme_id, is_gpa_based: true).exists?
  end

  class << self
    def find_by_learner_call_number(number, program_ids)
      return nil if number.blank?

      pgs_map = {}
      all_pgs = all_learner_calling_numbers(program_ids)
      all_pgs.each do |lp|
        l_numbers = lp[:learner_call_number] || []
        l_numbers = [l_numbers] unless l_numbers.is_a?(Array)
        l_numbers.each do |l_num|
          pgs_map[l_num[:number]] ||= []
          pgs_map[l_num[:number]] << lp[:program_id]
        end
      end

      pgs_map[number]
    end

    def visa_template_map
      hash = {}

      visa_template_ids = VisaTemplate.all.pluck(:id)

      programs = where("settings like '%:visa_template_id:%'").select(:id, :settings)

      programs.each do |prog|
        visa_template_id = prog.settings[:visa_template_id].to_i
        hash[prog.id] = visa_template_id if visa_template_ids.include?(visa_template_id)
      end

      hash
    end

    def fetch_programs_by_setting(settings)
      Program.select(:id, :settings)
             .where('settings like ?', "%#{settings}%")
             .pluck(:id, :settings)
             .to_h
    end

    private

    def all_learner_calling_numbers(program_ids)
      programs = Program.select(:id, :settings)
                        .where('id in (?) AND settings like ?', program_ids, '%learner_call_number%')

      programs.map do |l|
        { program_id: l.id, learner_call_number: l.settings[:learner_call_number] }
      end
    end
  end

  def custom_inst_dates_applicable?
    installment_options_compute == 'custom_dates'
  end
end
