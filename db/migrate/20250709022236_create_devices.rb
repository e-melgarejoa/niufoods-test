class CreateDevices < ActiveRecord::Migration[8.0]
  def change
    create_table :devices do |t|
      t.references :device_type, null: false, foreign_key: true
      t.string :uuid, null: false
      t.string :name
      t.string :manufacturer
      t.string :model
      t.string :serial_number
      t.string :firmware_version
      t.datetime :last_connection_at
      t.boolean :active

      t.timestamps
    end
    add_index :devices, :serial_number, unique: true, where: 'serial_number IS NOT NULL'
    add_index :devices, :active
  end
end
