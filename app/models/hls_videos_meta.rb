class HlsVideosMeta < ActiveRecord::Base
  scope :active, -> { where(active: true) }
  scope :is_video, -> { where(file_type: 'f') }
  scope :ai_srt_filter, lambda { |ai_srt|
    ai_srt ? where(ai_srt:) : where('ai_srt is null or ai_srt = false')
  }

  def set_olympus_token
    loop do
      self.olympus_token = SecureRandom.uuid
      break unless self.class.exists?(olympus_token:)
    end
  end

  def parse_and_create_directories
    components = key.split('/')
    paths = components[0..-2]
    filename = components[-1]

    running_path = ''
    id = -1
    paths.each do |component|
      running_path += "#{component}/"
      row = HlsVideosMeta.where(key: running_path).first
      if row.present?
        id = row.id
      else
        new_id = HlsVideosMeta.create({ name: component, file_type: 'd', key: running_path, active: true,
                                        parent: id }).id
        id = new_id
      end
    end

    { name: filename, parent: id }
  end

  def fetch_download_url
    download_url = ''
    download_url = "#{Constants::HlsVideosMeta::HLS_VIDEOS_DISTRIBUTION}/#{download_key}" if download_key.present?
    download_url
  end

  class << self
    def meta_details(video_meta_ids = [])
      details = {}

      video_metas = HlsVideosMeta.where(id: video_meta_ids)
      video_metas.each do |video_meta|
        details[video_meta.id] = {
          status: video_meta.status
        }
      end

      details
    end

    def new_output_key_prefix
      output_key_prefix = nil

      loop do
        output_key_prefix = SecureRandom.uuid
        break unless exists?(master_playlist_name: "#{output_key_prefix}.m3u8")
      end

      output_key_prefix
    end

    def new_download_key_prefix
      download_key_prefix = nil

      loop do
        download_key_prefix = SecureRandom.uuid
        break unless exists?(output_download_key: "#{download_key_prefix}.mp4")
      end

      download_key_prefix
    end

    def get_embed_code_for(olympus_token)
      video_url = get_video_url_for olympus_token
      "<div class='embed-responsive embed-responsive-16by9 iframe-video-container'>" \
        "<iframe class='embed-responsive-item' src='#{video_url}' width='300' height='150' " \
        "allowfullscreen='true' webkitallowfullscreen='true' mozallowfullscreen='true'></iframe>" \
        '</div>'
    end

    def get_video_url_for(olympus_token)
      "#{Settings.lti_base_url}/hls_videos/#{olympus_token}"
    end

    def get_video_duration(olympus_token)
      where(olympus_token:).active.is_video.select(:video_duration).first
    end

    def video_output_key_prefix
      if Rails.env.production?
        'HLS/production/'
      elsif Rails.env.migration? || Rails.env.staging?
        'HLS/migration/'
      elsif Rails.env.development?
        'HLS/development/'
      else
        'HLS/fallback/'
      end
    end

    def download_key_prefix
      if Rails.env.production?
        'nrael/p/'
      elsif Rails.env.migration? || Rails.env.staging?
        'nrael/m/'
      elsif Rails.env.development?
        'nrael/d/'
      else
        'nrael/f/'
      end
    end
  end
end
