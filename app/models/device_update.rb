class DeviceUpdate < ApplicationRecord
  belongs_to :device
  belongs_to :last_successful_request
  belongs_to :last_failed_request

  enum last_update_status: { success: 0, pending: 1, failed: 2, in_progress: 3 }

  enum operational_status: {
    unknown: 0,         # Initial state or when no recent info is available
    operative: 1,       # Device is functioning correctly
    warning: 2,         # Minor or potential issue detected
    trouble: 3,         # Problems requiring attention but not a complete failure
    failing: 4,         # Device is failing or has failed
    in_maintenance: 5   # Device is intentionally offline for maintenance
  }

  validates :device_id, presence: true, uniqueness: true
  validates :last_update_status, presence: true
  validates :operational_status, presence: true
end
