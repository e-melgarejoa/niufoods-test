class DeviceType < ApplicationRecord
    has_many :devices, dependent: :restrict_with_error

    validates :name, presence: true, uniqueness: { case_sensitive: false }
    validates :active, inclusion: { in: [true, false] }
end
