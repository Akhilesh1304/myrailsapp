module HlsVideos
  class CreateHlsJobService
    attr_accessor :video_meta_id, :download_key_prefix, :output_key_prefix, :aws_encryption_key_plain

    def initialize(video_meta_id)
      @video_meta_id = video_meta_id
    end

    def call
      generate_tokens
      video_convert_job = AwsMediaConvert::CreateJobService.new(create_job_params).call
      update_video_meta(video_convert_job)
    end

    private

    def generate_tokens
      @download_key_prefix = HlsVideosMeta.new_download_key_prefix
      @output_key_prefix = HlsVideosMeta.new_output_key_prefix
      @aws_encryption_key_plain = SecureRandom.hex(16)
    end

    def video_meta
      @video_meta ||= HlsVideosMeta.find_by(id: video_meta_id)
    end

    def update_video_meta(video_convert_job)
      video_meta_basic_fields(video_convert_job)
      video_meta_caption_fields
      video_meta.aws_encryption_key_plain = aws_encryption_key_plain
      video_meta.save!
    end

    def video_meta_basic_fields(video_convert_job)
      components = video_meta.key.split('/')
      filename = components[-1]
      video_meta.name = filename
      video_meta.job_id = video_convert_job.id
      video_meta.master_playlist_name = "#{output_key_prefix}.m3u8"
      video_meta.status = Constants::HlsVideosMeta::STATUS_TRANSCODING
      video_meta.output_download_key = "#{download_key_prefix}.mp4"
      video_meta.file_type = 'f'
      video_meta.format_version = Constants::HlsVideosMeta::FORMAT_HLS_V3
    end

    def video_meta_caption_fields
      video_meta.caption_prefixes = captions.map { |s| s[:lang] }
      video_meta.caption_paths = captions.map { |s| s[:key] }
    end

    def create_job_params
      hls_videos_bucket = Settings.hls_videos_bucket
      video_perfix = HlsVideosMeta.video_output_key_prefix

      {
        input_video_url: "s3://#{hls_videos_bucket}/#{video_meta.key}",
        output_base_url: "s3://#{hls_videos_bucket}/#{video_perfix}#{output_key_prefix}",
        file_output_base_url: "s3://#{hls_videos_bucket}/#{video_perfix}#{download_key_prefix}",
        hls_output_presets:,
        file_output_presets:,
        captions:,
        hls_encryption:
      }
    end

    def captions
      @captions || VideoProcessor::CaptionFilesService.new(video_meta.key, video_meta.ai_srt).call
    end

    def hls_output_presets
      [
        { name_modifier: '-224p', preset: Settings.aws_mediaconvert_custom_preset_name_224p },
        { name_modifier: '-360p', preset: Settings.aws_mediaconvert_custom_preset_name_360p },
        { name_modifier: '-540p', preset: Settings.aws_mediaconvert_custom_preset_name_540p },
        { name_modifier: '-720p', preset: Settings.aws_mediaconvert_custom_preset_name_720p },
        { name_modifier: '-1080p', preset: Settings.aws_mediaconvert_custom_preset_name_1080P }
      ]
    end

    def file_output_presets
      [
        { preset: Settings.aws_mediaconvert_custom_preset_name_download }
      ]
    end

    def hls_encryption
      {
        encryption_method: 'AES128',
        static_key_provider: {
          static_key_value: aws_encryption_key_plain,
          url: "#{Settings.lti_base_url}/api/v1/hls_videos/tokens/#{video_meta.olympus_token}"
        },
        type: 'STATIC_KEY'
      }
    end
  end
end
