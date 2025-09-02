module HlsVideos
  class UpdateLmsContentInfoService
    def initialize(video_meta_id:, is_video_duration_updated:)
      @video_meta_id = video_meta_id
      @is_video_duration_updated = is_video_duration_updated
    end

    def call
      video_meta = fetch_video_meta
      olympus_token = video_meta.olympus_token
      lms_content_infos = fetch_lms_content_infos(olympus_token)

      Rails.logger.info "Updating #{lms_content_infos.size} wiki pages
      having video with olympus_token: #{olympus_token}, video_meta_id: #{@video_meta_id}"

      module_item_ids = process_lms_content_infos(lms_content_infos, video_meta)

      update_video_watched_events(module_item_ids, video_meta) if @is_video_duration_updated

      Rails.logger.info "Updated wiki pages with olympus_token: #{olympus_token}, video_meta_id: #{@video_meta_id}"
    end

    private

    def fetch_video_meta
      HlsVideosMeta.find(@video_meta_id)
    end

    def fetch_lms_content_infos(olympus_token)
      LmsContentInfo.where("content_aux_details->>'olympus_token' = ?", olympus_token)
    end

    def process_lms_content_infos(lms_content_infos, _video_meta)
      module_item_ids = []

      lms_content_infos.each do |lms_content_info|
        course_id = lms_content_info.context_id
        page_id = lms_content_info.content_id

        lms_wiki_page = fetch_lms_wiki_page(page_id)
        unless lms_wiki_page.present?
          Rails.logger.info "Missing wiki page: #{page_id} in course: #{course_id}"
          next
        end

        mapping_info = fetch_mapping_info(course_id, page_id)
        next if mapping_info.blank?

        transaction_hash = build_transaction_hash(course_id, page_id, lms_wiki_page, mapping_info)

        module_item_ids.concat(mapping_info.map { |mapping| mapping['id'] })

        LmsContentInfoManager::ProcessTransactionHashService.new(transaction_hash).call

        Rails.logger.info "Updated wiki page: #{page_id} in course: #{course_id}"
      end

      module_item_ids
    end

    def fetch_lms_wiki_page(page_id)
      Lms::WikiPage.where(id: page_id).where.not(workflow_state: 'deleted').first
    end

    def fetch_mapping_info(course_id, page_id)
      UseCase::LmsContentInfo::GetMappingInfo.new(course_id, page_id).call
    end

    def build_transaction_hash(course_id, page_id, lms_wiki_page, mapping_info)
      {
        course_id:,
        wiki_page_id: page_id,
        page_info: lms_wiki_page,
        mapping_info:
      }
    end

    def update_video_watched_events(module_item_ids, video_meta)
      UseCase::VideoWatchedEvents::UpdateVideoWatchedEvents.new(
        media_type: ::LmsContentInfo::VIDEO_TYPES[:GL_HLS],
        module_item_ids:,
        duration: video_meta.video_duration
      ).call
    end
  end
end
