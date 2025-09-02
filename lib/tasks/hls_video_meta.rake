# RAILS_ENV=staging bundle exec rake hls_video_meta:update_ai_response
namespace :hls_video_meta do
  desc 'Pool hls video meta status'
  task update_meta_details: :environment do
    HlsVideos::UpdateMetaDetailsService.new.delay(queue: 'hls_video_processing_queue').call
  end
end
