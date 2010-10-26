class Album < ActiveRecord::Base
  has_many :photos, :dependent => :destroy
  has_one :flickr_info, :dependent => :destroy

  belongs_to :owner, :polymorphic => true
end
