class DeviceApiRequest < ApplicationRecord
  belongs_to :device

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  validates :device_id, presence: true
  validates :status, presence: true
  validates :request_payload, presence: true
end
