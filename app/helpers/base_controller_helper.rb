module BaseControllerHelper
  def app_names
    {
      'program_groups' => :batch_home,
      'program_group_activities' => :batch_home,
      'program_group_settings' => :batch_home,
      'users' => :batch_home,
      'engagement_metrics' => :batch_home,
      'complementary_courses' => :batch_home,
      'emails' => :batch_home,
      'chats' => :batch_home,
      'sendgrid' => :batch_home,
      'learner_listings' => :batch_home,
      'custom_filters' => :batch_home,
      'payments' => :batch_payments,
      'program_fee_extensions' => :batch_payments,
      'feedback' => :user_feedback,
      'gradebooks' => :batch_gradebook,
      'attendances' => :attendance_sheet,
      'external_content' => :manage_external_content,
      'referrals' => :referrals,
      'mentored_learnings' => :mentorship_session_planner,
      'mentored_group_sessions' => :mentorship_session_planner,
      'recordings' => :mentorship_session_planner,
      'media_processings_internal_api' => :media_processings_internal_api,
      'moderator_assessment_mappings' => :evaluation_moderation,
      'quicksights' => :quicksight_reports,
      'coding_labs' => :manage_coding_labs,
      'facilitator_user_details' => :gl_gurus_catalog,
      'course_owners' => :course_owner_mappings,
      'user_availability_mappings' => :course_owner_mappings,
      'course_templates' => :course_owner_mappings,
      'programs' => :manage_programs,
      'program_settings' => :manage_programs,
      'visa' => :manage_visa_applications,
      'facilitator_user' => :gl_gurus_catalog,
      'facilitator_user_notes' => :gl_gurus_catalog,
      'offline_payments' => :manage_payments_csv_upload,
      'batch_rosters' => :manage_batch_rosters
    }.merge(manage_azure_notebook_app)
      .merge(ai_mcq_gen_app)
      .merge(manage_groups)
      .merge(manage_course_level_app)
      .merge(manage_certificates)
      .merge(manage_workflow)
      .merge(manage_program_support)
      .merge(batch_home_apps)
  end

  private

  def batch_home_apps
    {
      'student_batch_states' => :batch_home,
      'hls_videos' => :batch_home,
      'attrition_predictions' => :batch_home,
      'assessments' => :batch_home,
      'alternate_pm_call_assignments' => :batch_home,
      'quiz_questions' => :batch_home,
      'quiz_groups' => :batch_home,
      'quizzes' => :batch_home,
      'question_banks' => :batch_home
    }
  end

  def manage_course_level_app
    {
      'modules' => :batch_home,
      'announcements' => :batch_home,
      'discussion_topics' => :batch_home,
      'course_users' => :batch_home,
      'rubrics' => :batch_home,
      'courses' => :batch_home,
      'assignment_groups' => :batch_home,
      'course_imports' => :batch_home
    }
  end

  def manage_azure_notebook_app
    {
      'azure_labs' => :manage_azure_labs,
      'gl_lab_variant' => :manage_azure_labs,
      'manage_jupyter_labs' => :manage_jupyter_labs,
      'jupyter_lab_notebook' => :manage_jupyter_labs,
      'jupyter_lab_access_mapping' => :manage_jupyter_labs,
      'jupyter_lab_user_mappings' => :manage_jupyter_labs
    }
  end

  def manage_groups
    {
      'group_categories' => :batch_home,
      'group_memberships' => :batch_home,
      'groups' => :batch_home,
      'group_category_mappings' => :batch_home
    }
  end

  def ai_mcq_gen_app
    {
      'ai_srt_questions' => :manage_ai_mcq_gen,
      'ai_srt_topics' => :manage_ai_mcq_gen,
      'ai_gen_courses' => :manage_ai_mcq_gen,
      'ai_contexts' => :manage_ai_contexts,
      'ai_context_mappings' => :manage_ai_contexts,
      'subtitles' => :setup_admin_roles
    }
  end

  def manage_certificates
    {
      'certificates' => :certificates,
      'ceu_certificates' => :certificates
    }
  end

  def manage_program_support
    { 'support_ticket_conversations' => :centralised_support,
      'support_tickets' => :centralised_support }
  end

  def manage_workflow
    {
      'workflow_actions' => :centralised_support,
      'workflow_entity_mappings' => :centralised_support,
      'workflow_steps' => :centralised_support,
      'workflow_bulk_operations' => :centralised_support
    }
  end
end
