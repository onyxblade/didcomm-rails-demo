class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.string :didcomm_id
      t.string :direction
      t.string :from_did
      t.string :to_did
      t.string :message_type
      t.text :body
      t.text :packed_message
      t.string :visibility
      t.string :status

      t.timestamps
    end
  end
end
