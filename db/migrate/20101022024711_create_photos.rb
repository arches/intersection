class CreatePhotos < ActiveRecord::Migration
  def self.up
    create_table :photos do |t|
      t.string :url
      t.string :caption
      t.integer :album_id
      t.string :remote_id

      t.timestamps
    end
  end

  def self.down
    drop_table :photos
  end
end
