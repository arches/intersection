class Album < ActiveRecord::Base
  has_many :photos, :dependent => :destroy
  has_one :flickr_album, :dependent => :destroy

  belongs_to :owner, :polymorphic => true
end
