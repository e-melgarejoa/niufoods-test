require 'sidekiq/web'
Rails.application.routes.draw do

  get "up" => "rails/health#show", as: :rails_health_check
  mount Sidekiq::Web => '/sidekiq' # Mount Sidekiq web interface at /sidekiq only for development env

end
