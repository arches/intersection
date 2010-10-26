class CreateAlbums < ActiveRecord::Migration
  def self.up
    create_table :albums do |t|
      t.string :name
      t.integer :owner_id
      t.string :owner_type
      t.string :remote_id

      t.timestamps
    end
  end

  def self.down
    drop_table :albums
  end
end
