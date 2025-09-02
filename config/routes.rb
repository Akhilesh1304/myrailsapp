Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      resources :quicksights, only: %i[index show]

      scope :media_processing do
        post :process_video, to: 'media_processing#process_video_internal_api'
        post :process_folder, to: 'media_processing#process_folder_internal_api'
        post :media_status, to: 'media_processing#media_status'
      end
      
    end
  end
end
