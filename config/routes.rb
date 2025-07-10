require 'sidekiq/web'
Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: "_interslice_session"
Rails.application.routes.draw do

  get 'devices_dashboard', to: 'devices_dashboard#index', as: 'devices_dashboard'
  get 'devices_dashboard/:uuid', to: 'devices_dashboard#show', as: 'device_dashboard_detail'

  get 'locals_dashboard', to: 'locals_dashboard#index', as: 'locals_dashboard'
  get 'locals_dashboard/:id', to: 'locals_dashboard#show', as: 'local_dashboard_detail'

  get "up" => "rails/health#show", as: :rails_health_check
  mount Sidekiq::Web => "/sidekiq"
  namespace :api do
    namespace :v1 do
      post 'devices/update_status', to: 'devices#update_status'
      post 'devices/:uuid/report_status', to: 'devices#report_status' # reporte de estado
    end
  end
  
  root 'devices_dashboard#index'

end
