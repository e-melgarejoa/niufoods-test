class LocalDevice < ApplicationRecord
  belongs_to :local
  belongs_to :device

  validates :assigned_from, presence: true
  validates :is_current, inclusion: { in: [true, false] }

  validate :only_one_current_assignment, if: :is_current?

  # Desactivamos la asignación anterior si se cambia el estado de `is_current`
  before_save :deactivate_previous_current, if: :is_current_changed?

  private

  def only_one_current_assignment
    if new_record? || is_current_changed?(from: false, to: true)
      if device.local_devices.where(is_current: true).where.not(id: id).exists?
        errors.add(:device, "already has a current assignment to another location. Deactivate the previous one first.")
      end
    end
  end

  def deactivate_previous_current
    if is_current?
      # Encuentra y actualiza cualquier otra asignación actual para este dispositivo a falso.
      device.local_devices.where(is_current: true).where.not(id: id).find_each do |ld|
        ld.update(is_current: false, assigned_until: Time.current)
      end
    end
  end
end
