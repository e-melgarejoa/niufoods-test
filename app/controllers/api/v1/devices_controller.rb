# app/controllers/api/v1/devices_controller.rb
module Api
  module V1
    class DevicesController < ActionController::API
      skip_before_action :verify_authenticity_token, raise: false

      # Este endpoint recibe los datos de estado periódicos de un dispositivo.
      def update_status
        Rails.logger.info "--- INICIANDO: Api::V1::DevicesController#update_status ---"
        Rails.logger.info "Parámetros recibidos: #{params.inspect}"

        # Extrae el device_uuid y los datos del payload.
        device_uuid = update_status_params[:device_uuid]
        payload = update_status_params[:data] || {}

        if device_uuid.blank?
          Rails.logger.warn "ERROR: 'device_uuid' está vacío en la solicitud de update_status."
          return render json: { error: "'device_uuid' es requerido." }, status: :bad_request
        end

        device = Device.find_by(uuid: device_uuid)
        unless device
          Rails.logger.warn "ERROR: Dispositivo con UUID '#{device_uuid}' no encontrado para update_status."
          return render json: { error: "Dispositivo con UUID '#{device_uuid}' no encontrado." }, status: :not_found
        end

        begin
          device_api_request = device.device_api_requests.create!(
            request_payload: payload,
            api_endpoint: request.path, # Guarda el endpoint que recibió la solicitud
            status: :pending # Inicialmente en estado pendiente
          )

          DeviceUpdateJob.perform_async(device_api_request.id)

          Rails.logger.info "ÉXITO: Solicitud de actualización de dispositivo encolada para UUID #{device_uuid}. ID de solicitud: #{device_api_request.id}"
          render json: {
            message: "Solicitud de actualización de dispositivo recibida y encolada para procesamiento.",
            request_id: device_api_request.id,
            device_uuid: device_uuid
          }, status: :accepted # HTTP 202 Accepted indica que la solicitud fue aceptada para procesamiento

        rescue ActiveRecord::RecordInvalid => e
          # Captura errores de validación de ActiveRecord al intentar crear DeviceApiRequest
          Rails.logger.error "ERROR (ActiveRecord::RecordInvalid): Fallo al crear DeviceApiRequest para UUID #{device_uuid}: #{e.message}"
          render json: { error: "Fallo al guardar la solicitud API: #{e.message}" }, status: :unprocessable_entity
        rescue => e
          # Captura cualquier otro error inesperado durante el proceso
          Rails.logger.error "ERROR INESPERADO en DevicesController#update_status para UUID #{device_uuid}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n") # Registra el stack trace completo
          render json: { error: "Ocurrió un error interno del servidor al procesar su solicitud." }, status: :internal_server_error
        ensure
          Rails.logger.info "--- FINALIZANDO: Api::V1::DevicesController#update_status ---"
        end
      end

      def report_status
        Rails.logger.info "--- INICIANDO: Api::V1::DevicesController#report_status ---"
        Rails.logger.info "Parámetros recibidos (incluyendo UUID de URL): #{params.inspect}"

        device_uuid = params[:uuid] # Obtiene el UUID de la URL
        current_operational_status = report_status_params[:current_operational_status]

        if device_uuid.blank? || current_operational_status.blank?
          Rails.logger.warn "ERROR: 'device_uuid' o 'current_operational_status' están vacíos en la solicitud de report_status."
          return render json: { error: "'device_uuid' y 'current_operational_status' son requeridos." }, status: :bad_request
        end

        device = Device.find_by(uuid: device_uuid)
        unless device
          Rails.logger.warn "ERROR: Dispositivo con UUID '#{device_uuid}' no encontrado para report_status."
          return render json: { error: "Dispositivo con UUID '#{device_uuid}' no encontrado." }, status: :not_found
        end

        begin
          device_update = device.device_update || device.create_device_update # Asegura que haya un DeviceUpdate asociado
          device_update.update!(operational_status: current_operational_status, last_sync_time: Time.current)

          Rails.logger.info "ÉXITO: Estado operacional actualizado para dispositivo #{device_uuid} a '#{current_operational_status}'."
          render json: {
            message: "Estado operacional de dispositivo actualizado correctamente.",
            device_uuid: device_uuid,
            new_status: current_operational_status
          }, status: :ok # HTTP 200 OK para una actualización directa y exitosa

        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error "ERROR (ActiveRecord::RecordInvalid): Fallo al actualizar estado para UUID #{device_uuid}: #{e.message}"
          render json: { error: "Fallo al actualizar el estado del dispositivo: #{e.message}" }, status: :unprocessable_entity
        rescue => e
          Rails.logger.error "ERROR INESPERADO en DevicesController#report_status para UUID #{device_uuid}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          render json: { error: "Ocurrió un error interno del servidor al procesar su solicitud de reporte de estado." }, status: :internal_server_error
        ensure
          Rails.logger.info "--- FINALIZANDO: Api::V1::DevicesController#report_status ---"
        end
      end

      private

      def update_status_params
        params.permit(
          :device_uuid,
          data: [ # `data` es un hash anidado
            :firmware_version, :battery_level, :temperature, :uptime_hours, :operational_status, :sync_time,
            # Campos específicos de tipos de dispositivo
            :screen_brightness, :disk_usage_percent,
            :humidity, :ambient_light,
            :transactions_today, :last_transaction_value,
            :current_content_id, :playlist_version,
            :paper_level_percent, :toner_level_percent, :pages_printed_since_last_service,
            # Campo para simular errores en el worker (si tu worker lo interpreta)
            :force_server_error
          ]
        )
      end

      def report_status_params
        params.permit(:current_operational_status)
      end
    end
  end
end