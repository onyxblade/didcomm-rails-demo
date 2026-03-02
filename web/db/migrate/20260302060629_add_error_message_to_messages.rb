class AddErrorMessageToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :error_message, :text
  end
end
