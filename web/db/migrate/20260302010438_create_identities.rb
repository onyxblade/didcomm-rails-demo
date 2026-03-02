class CreateIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :identities do |t|
      t.string :domain
      t.string :did
      t.text :ed25519_public_jwk
      t.text :ed25519_private_jwk
      t.text :x25519_public_jwk
      t.text :x25519_private_jwk

      t.timestamps
    end
  end
end
