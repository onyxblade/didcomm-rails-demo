class DropAdmins < ActiveRecord::Migration[8.1]
  def change
    drop_table :admins
  end
end
