class DeviceUpdateJob
  include Sidekiq::Job
  sidekiq_options retry: 3, queue: 'device_updates'

  def perform(device_api_request_id)
    device_api_request = DeviceApiRequest.find_by(id: device_api_request_id)

    unless device_api_request
      Rails.logger.warn "DeviceUpdateJob: DeviceApiRequest with ID #{device_api_request_id} not found. Skipping."
      return 
    end

    # Evitar reprocesar si ya está completado o en progreso
    if device_api_request.completed? || device_api_request.processing?
      Rails.logger.info "DeviceUpdateJob: DeviceApiRequest #{device_api_request.id} is already in state '#{device_api_request.status}'. Skipping re-processing."
      return
    end

    device_api_request.update!(status: :processing, processed_at: Time.current)
    Rails.logger.info "DeviceUpdateJob: Started processing DeviceApiRequest ID: #{device_api_request.id} for device UUID: #{device_api_request.device.uuid}"

    device = device_api_request.device
    device_update = device.device_update

    device_update.update!(
      last_update_status: :in_progress,
      last_updated_at: Time.current,
      last_error_message: nil
    )

    local = device.local_devices.find_by(is_current: true)&.local

    begin
      # Simular la llamada a la API del dispositivo
      # {
      #   "firmware_version": "1.2.3",
      #   "battery_level": 85,
      #   "temperature": 25.5,
      #   "operational_status": "operative",
      #   "sync_time": "2025-07-08T23:00:00Z"
      # }
      payload = device_api_request.request_payload
      puts "Processing payload: #{payload.inspect}"
      puts payload['operational_status']

      reported_firmware = payload['firmware_version']
      reported_operational_status_str = payload['operational_status'] # Estado operativo reportado por el dispositivo (string)
      reported_sync_time = payload['sync_time']

      operational_status_enum = if reported_operational_status_str.present? &&
                                   DeviceUpdate.operational_statuses.key?(reported_operational_status_str.to_sym)
                                  reported_operational_status_str.to_sym
                                else
                                  :unknown # Valor por defecto si no es válido o está ausente
                                end
      
      # Actualizar el dispositivo con la información reportada
      device.update!(last_connection_at: Time.current)

      device_update.update!(
        last_update_status: :success, # La ejecución del worker fue exitosa
        last_updated_at: Time.current,
        last_sync_time: reported_sync_time.present? ? Time.parse(reported_sync_time) : Time.current,
        current_firmware_version: reported_firmware,
        operational_status: operational_status_enum, # Usa el estado reportado por el dispositivo
        last_successful_request: device_api_request, # Enlaza al request que disparó esta actualización exitosa
        last_error_message: nil # Limpia cualquier error previo en el resumen
      )

      # Marcar la solicitud API como completada
      device_api_request.update!(status: :completed, completed_at: Time.current)
      Rails.logger.info "DeviceUpdateJob: Successfully processed DeviceApiRequest ID: #{device_api_request.id}. Device #{device.uuid} updated."

    rescue StandardError => e
      Rails.logger.error "DeviceUpdateJob: Error processing DeviceApiRequest ID: #{device_api_request.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n") # Loguea el stack trace completo para depuración

      # Actualizar el registro DeviceUpdate para reflejar el fallo
      device_update.update!(
        last_update_status: :failed, # El intento de actualización falló
        last_updated_at: Time.current,
        last_failed_request: device_api_request, # Enlaza al DeviceApiRequest que falló
        last_error_message: e.message,
        operational_status: :trouble
      )

      # Marcar la solicitud API como fallida
      device_api_request.update!(
        status: :failed,
        completed_at: Time.current,
        error_message: e.message,
        stack_trace: e.backtrace.join("\n")
      )
      raise
    ensure
      if local.present?
        Rails.logger.info "DeviceUpdateJob: Updating operational status for Local '#{local.name}' (ID: #{local.id})."
        local.update_operational_status! # Llama al método para actualizar el estado del local
      else
        Rails.logger.warn "DeviceUpdateJob: Device #{device.uuid} is not currently assigned to any Local. Skipping local status update."
      end  
    end
  end
end
