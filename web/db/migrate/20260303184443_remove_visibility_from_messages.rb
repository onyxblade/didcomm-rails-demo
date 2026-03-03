class RemoveVisibilityFromMessages < ActiveRecord::Migration[8.1]
  def change
    remove_column :messages, :visibility, :string
  end
end
