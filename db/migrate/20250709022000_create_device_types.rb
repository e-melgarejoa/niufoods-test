class CreateDeviceTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :device_types do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    add_index :device_types, :name, unique: true
  end
end
