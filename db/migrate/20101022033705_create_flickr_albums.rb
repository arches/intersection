class CreateFlickrAlbums < ActiveRecord::Migration
  def self.up
    create_table :flickr_albums do |t|
      t.string :farm
      t.string :server
      t.string :photoset_id
      t.string :secret
      t.integer :album_id

      t.timestamps
    end
  end

  def self.down
    drop_table :flickr_infos
  end
end
