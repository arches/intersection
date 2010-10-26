class CreateFlickrInfos < ActiveRecord::Migration
  def self.up
    create_table :flickr_infos do |t|
      t.string :farm
      t.string :server
      t.string :remote_id
      t.string :secret
      t.string :owner_type
      t.string :owner_id

      t.timestamps
    end
  end

  def self.down
    drop_table :flickr_infos
  end
end
