class CreateFlickrAccounts < ActiveRecord::Migration
  def self.up
    create_table :flickr_accounts do |t|
      t.string :remote_id
      t.string :token

      t.timestamps
    end
  end

  def self.down
    drop_table :flickr_accounts
  end
end
