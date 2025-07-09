class CreateLocalDevices < ActiveRecord::Migration[8.0]
  def change
    create_table :local_devices do |t|
      t.references :local, null: false, foreign_key: true
      t.references :device, null: false, foreign_key: true
      t.datetime :assigned_from
      t.datetime :assigned_until
      t.boolean :is_current # Indica si esta es la tarea activa actual

      t.timestamps
    end
    # Nos aseguramos que solo haya una tarea activa por local
    add_index :local_devices, [:device_id, :is_current], unique: true, where: 'is_current = true'
  end
end
