class LocalsDashboardController < ApplicationController
  def index
    @locales = Local.includes(local_devices: { device: :device_update })
                    .order(:name)
                    .page(params[:page])
                    .per(20)
  end

  def show
    @local = Local.includes(local_devices: { device: [:device_type, :device_update] })
                  .find(params[:id])

    @devices_in_local = @local.devices.joins(:local_devices)
                              .where(local_devices: { is_current: true })
                              .includes(:device_type, :device_update) 
                              .order('devices.name') 
                              .page(params[:device_page]) 
                              .per(10) 

  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Local con ID '#{params[:id]}' no encontrado."
    redirect_to locals_dashboard_path
  end
end