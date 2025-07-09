class CreateDeviceUpdates < ActiveRecord::Migration[8.0]
  def change
    create_table :device_updates do |t|
      t.references :device, null: false, foreign_key: true
      t.integer :last_update_status, default: 1, null: false # 0: success, 1: pending, 2: failed, 3: in_progress (enum)
      t.integer :operational_status, default: 0, null: false # 0: unknown, 1: operative, 2: warning, 3: trouble, 4: failing, 5: in_maintenance (enum)
      t.datetime :last_updated_at # Timestamp of the last time the device was updated
      t.datetime :last_sync_time # The last time the device was synchronized with the server

      t.string :current_firmware_version # The firmware version currently installed on the device
      t.string :desired_firmware_version # The firmware version the device should be updated to, if applicable

      # References to the last DeviceApiRequest that was successful/failed
      t.references :last_successful_request, foreign_key: { to_table: :device_api_requests }
      t.references :last_failed_request, foreign_key: { to_table: :device_api_requests }

      t.text :last_error_message # Error message from the last failed update attempt

      t.timestamps
    end
    add_index :device_updates, :last_update_status
    add_index :device_updates, :operational_status
  end
end
