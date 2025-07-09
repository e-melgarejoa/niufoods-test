class Device < ApplicationRecord
  belongs_to :device_type

  has_many :local_devices, dependent: :destroy
  has_many :locales, through: :local_devices

  has_many :device_api_requests, dependent: :destroy

  has_one :device_update, dependent: :destroy

  validates :uuid, presence: true, uniqueness: true
  validates :active, inclusion: { in: [true, false] }
  validates :device_type_id, presence: true

  after_create :create_device_update_record

  private

  def create_device_update_record
    DeviceUpdate.create!(
      device: self,
      last_update_status: :in_progress,
      operational_status: :unknown
    )
  end
end
