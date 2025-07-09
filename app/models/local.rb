class Local < ApplicationRecord
    has_many :local_devices, dependent: :destroy
    has_many :devices, through: :local_devices

    validates :name, presence: true, uniqueness: true
end
