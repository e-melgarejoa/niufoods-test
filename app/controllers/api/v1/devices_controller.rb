module Api
  module V1
    class DevicesController < ActionController::API

      #skip_before_action :verify_authenticity_token

      # Recibe un payload completo de un dispositivo para procesamiento asíncrono.
      def update_status
        device_uuid = update_status_params[:device_uuid]
        payload = update_status_params[:data] || {} # El payload principal viene bajo la clave :data

        if device_uuid.blank?
          return render json: { error: "device_uuid is required." }, status: :bad_request
        end

        device = Device.find_by(uuid: device_uuid)
        unless device
          return render json: { error: "Device with UUID '#{device_uuid}' not found." }, status: :not_found
        end

        begin
          device_api_request = device.device_api_requests.create!(
            request_payload: payload,
            api_endpoint: request.path,
            status: :pending 
          )

          DeviceUpdateJob.perform_async(device_api_request.id)

          render json: {
            message: "Device update request received and queued for processing.",
            request_id: device_api_request.id,
            device_uuid: device_uuid
          }, status: :accepted 

        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error "API Error creating DeviceApiRequest for UUID #{device_uuid}: #{e.message}"
          render json: { error: "Failed to save API request: #{e.message}" }, status: :unprocessable_entity
        rescue => e
          Rails.logger.error "API Error in DevicesController#update_status for UUID #{device_uuid}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          render json: { error: "An internal server error occurred while processing your request." }, status: :internal_server_error
        end
      end

      # Para actualizaciones rápidas y directas del estado operativo.
      def report_status
        device_uuid = params[:uuid] # UUID viene de la URL
        reported_status_str = report_status_params[:current_operational_status]

        if device_uuid.blank?
          return render json: { error: "device_uuid is required in URL." }, status: :bad_request
        end

        device = Device.find_by(uuid: device_uuid)
        unless device
          return render json: { error: "Device with UUID '#{device_uuid}' not found." }, status: :not_found
        end

        device_update = device.device_update
        unless device_update
          return render json: { error: "DeviceUpdate record not found for device '#{device_uuid}'." }, status: :not_found
        end

        begin
          operational_status_enum = if reported_status_str.present? &&
                                       DeviceUpdate.operational_statuses.key?(reported_status_str.to_sym)
                                      reported_status_str.to_sym
                                    else
                                      :unknown
                                    end

          device_update.update!(
            operational_status: operational_status_enum,
            last_sync_time: Time.current # Registrar la hora de la última sincronización
          )

          render json: {
            message: "Operational status updated successfully.",
            device_uuid: device.uuid,
            new_status: device_update.operational_status # Muestra el estado actualizado
          }, status: :ok

        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error "API Error updating DeviceUpdate for UUID #{device_uuid}: #{e.message}"
          render json: { error: "Failed to update status: #{e.message}" }, status: :unprocessable_entity
        rescue => e
          Rails.logger.error "API Error in DevicesController#report_status for UUID #{device_uuid}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          render json: { error: "An internal server error occurred while reporting status." }, status: :internal_server_error
        end
      end

      private

      def update_status_params
        params.permit(
          :device_uuid, 
          data: [       
            :firmware_version, :battery_level, :temperature, :uptime_hours, :operational_status, :sync_time,
            :screen_brightness, :disk_usage_percent, :humidity, :ambient_light, :transactions_today,
            :last_transaction_value, :current_content_id, :playlist_version, :paper_level_percent,
            :toner_level_percent, :pages_printed_since_last_service,
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