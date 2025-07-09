class DeviceUpdate < ApplicationRecord
  belongs_to :device
   belongs_to :last_successful_request, class_name: 'DeviceApiRequest', optional: true
  belongs_to :last_failed_request, class_name: 'DeviceApiRequest', optional: true

  enum :last_update_status, {
    pending: 0,
    in_progress: 1,
    success: 2,
    failed: 3
  }

 enum :operational_status, {
    unknown: 0,
    operative: 1,
    warning: 2,
    trouble: 3,
    failing: 4,
    in_maintenance: 5
  }
  
  validates :device_id, presence: true, uniqueness: true
  validates :last_update_status, presence: true
  validates :operational_status, presence: true
end
