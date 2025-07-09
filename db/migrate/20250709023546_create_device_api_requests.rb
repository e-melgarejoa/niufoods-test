class CreateDeviceApiRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :device_api_requests do |t|
      t.references :device, null: false, foreign_key: true
      t.string :sidekiq_job_id, index: { unique: true, where: 'sidekiq_job_id IS NOT NULL' }
      t.integer :status, default: 0, null: false # 0: pending, 1: processing, 2: completed, 3: failed (enum status)
      t.jsonb :request_payload # Store the request payload as JSON
      t.string :api_endpoint
      t.datetime :processed_at # Timestamp when the request was processed
      t.datetime :completed_at # Timestamp when the request was completed
      t.text :error_message
      t.text :stack_trace # Store the stack trace in case of errors
      t.integer :retries_count, default: 0, null: false # Count of retries for the request

      t.timestamps
    end
    add_index :device_api_requests, :status
  end
end
