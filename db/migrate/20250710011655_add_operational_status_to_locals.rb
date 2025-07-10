class AddOperationalStatusToLocals < ActiveRecord::Migration[8.0]
  def change
    add_column :locals, :operational_status, :integer, default: 0 #'unknown'
  end
end
