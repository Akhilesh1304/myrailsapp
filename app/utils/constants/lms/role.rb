module Constants
  module Lms
    module Role
      GLOBAL_LISTING_ACCESS_ROLES = ['Ops Manager', 'Business Unit Head', 'TechOnCall', 'TechOnCallSiteAdm',
                                     'Program Manager', 'AccountAdmin'].freeze
      DIGITAL_CAMPUS_ROLES = ['Campus Admin', 'Campus IT', 'Campus Guru',
                              'Batch Admin'].freeze
      OPS_HEAD_ROLE = ['OPS Head'].freeze
      BU_HEAD_ROLE = ['BU Head'].freeze
      OPS_MANAGER_ROLE_ID = 29

      COURSE_OWNER_ACAD_ROLES = ['Acad Ops Lead - New', 'Acad Ops'].freeze
      COURSE_OWNER_LEAD_ROLES = ['Acad Ops Lead - New'].freeze

      COURSE_OWNER_EDIT_ROLES = ['Acad Ops Lead - New', 'Acad Ops Course Owner Admin',
                                 'TechOnCall', 'TechOnCallSiteAdm', 'AccountAdmin', 'BusinessAdmin'].freeze

      COURSE_OWNER_ROLES = ['Acad Ops Lead - New', 'Acad Ops', 'Program Manager',
                            'Acad Ops Course Owner Admin', 'TechOnCall', 'TechOnCallSiteAdm',
                            'AccountAdmin', 'BusinessAdmin'].freeze

      QC_APPLICABLE_ROLES = ['Acad Ops', 'Program Manager', 'Business Admin'].freeze

      GLA_PEOPLE_ROLES = %w[StudentEnrollment TaEnrollment].freeze
    end
  end
end
