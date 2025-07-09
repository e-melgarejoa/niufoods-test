# app/controllers/api/v1/devices_controller.rb
module Api
  module V1
    class DevicesController < ApplicationController
      skip_before_action :verify_authenticity_token

      def update_status
        device_uuid = params[:device_uuid]
        payload = params[:data] || {}

        if device_uuid.blank?
          render json: { error: "device_uuid is required." }, status: :bad_request and return
        end

        device = Device.find_by(uuid: device_uuid)
        unless device
          render json: { error: "Device with UUID '#{device_uuid}' not found." }, status: :not_found and return
        end

        device_api_request = device.device_api_requests.create!(
          request_payload: payload,
          api_endpoint: request.path
        )

        # Encola el DeviceUpdateWorker
        DeviceUpdateWorker.perform_async(device_api_request.id)

        render json: {
          message: "Device update request received and queued for processing.",
          request_id: device_api_request.id,
          device_uuid: device_uuid
        }, status: :accepted
      rescue => e
        Rails.logger.error "Error receiving device update for UUID #{device_uuid}: #{e.message}"
        render json: { error: "Failed to process device update request: #{e.message}" }, status: :internal_server_error
      end

      # POST /api/v1/devices/:uuid/report_status (reafirmando el endpoint del ejemplo anterior)
      def report_status
        device_uuid = params[:uuid]
        reported_status_str = params[:current_operational_status] # String from device

        device = Device.find_by(uuid: device_uuid)
        unless device
          render json: { error: "Device with UUID '#{device_uuid}' not found." }, status: :not_found and return
        end

        device_update = device.device_update
        unless device_update
          render json: { error: "DeviceUpdate record not found for device '#{device_uuid}'." }, status: :not_found and return
        end

        operational_status_enum = if reported_status_str.present? &&
                                     DeviceUpdate.operational_statuses.key?(reported_status_str.to_sym)
                                    reported_status_str.to_sym
                                  else
                                    :unknown
                                  end

        device_update.update!(
          operational_status: operational_status_enum,
          last_sync_time: Time.current
        )

        render json: { message: "Operational status updated successfully.", device_uuid: device.uuid, new_status: device_update.operational_status }, status: :ok
      rescue => e
        Rails.logger.error "Error reporting status for device #{device_uuid}: #{e.message}"
        render json: { error: "Failed to report status: #{e.message}" }, status: :internal_server_error
      end

    end
  end
end