class CreateLocals < ActiveRecord::Migration[8.0]
  def change
    create_table :locals do |t|
      t.string :name, null: false
      t.string :address
      t.string :city
      t.string :region

      t.timestamps
    end
    add_index :locals, :name, unique: true
  end
end
