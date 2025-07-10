class DevicesDashboardController < ApplicationController

  def index
   @devices = Device.includes(:device_type, :device_update, local_devices: :local)
                     .order(:name)
                     .page(params[:page])
                     .per(20)            
  end

  def show
    @device = Device.includes(:device_type, :device_update, :device_api_requests, local_devices: :local)
                    .find_by!(uuid: params[:uuid])
    @recent_api_requests = @device.device_api_requests.order(created_at: :desc).limit(10)

  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Dispositivo con UUID '#{params[:uuid]}' no encontrado."
    redirect_to devices_dashboard_path
  end
end