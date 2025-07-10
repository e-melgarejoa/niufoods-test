# app/models/local.rb
class Local < ApplicationRecord
  has_many :local_devices, dependent: :destroy
  has_many :devices, through: :local_devices

  enum :operational_status, {
    unknown: 0,
    operative: 1,
    warning: 2,
    trouble: 3,
    failing: 4,
    in_maintenance: 5
  }

  validates :name, presence: true, uniqueness: true
  validates :operational_status, presence: true

 
  def update_operational_status!
    # Obtiene todos los estados operativos de los dispositivos activos asociados a este local
     device_statuses = devices.joins(:local_devices)
                             .where(local_devices: { is_current: true, local_id: self.id })
                             .joins(:device_update)
                             .pluck('device_updates.operational_status')
                             .map(&:to_sym)
 
    # Lógica para determinar el estado general del local
    new_status = if device_statuses.empty?
                   :unknown # O un estado por defecto si no hay dispositivos
                 elsif device_statuses.include?(:failing)
                   :failing
                 elsif device_statuses.include?(:trouble)
                   :trouble
                 elsif device_statuses.include?(:warning)
                   :warning
                 elsif device_statuses.all? { |status| status == :operative || status == :in_maintenance || status == :unknown }
                   :operative 
                 else
                   :unknown
                 end

    if self.operational_status != new_status.to_s
      update!(operational_status: new_status)
      Rails.logger.info "LocalUpdateJob: Local '#{name}' (ID: #{id}) operational status updated to '#{new_status}'."
    else
      Rails.logger.info "LocalUpdateJob: Local '#{name}' (ID: #{id}) operational status remains '#{new_status}'."
    end
  end
end