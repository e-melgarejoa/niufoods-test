require 'sidekiq/web'
Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: "_interslice_session"
Rails.application.routes.draw do

  get "up" => "rails/health#show", as: :rails_health_check
  mount Sidekiq::Web => "/sidekiq"
  namespace :api do
    namespace :v1 do
      post 'devices/update_status', to: 'devices#update_status'
      post 'devices/:uuid/report_status', to: 'devices#report_status' # reporte de estado
    end
  end
end
