class RemoveDomainAndDidFromIdentities < ActiveRecord::Migration[8.1]
  def change
    remove_column :identities, :domain, :string
    remove_column :identities, :did, :string
  end
end
