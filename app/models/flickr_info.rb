class FlickrInfo < ActiveRecord::Base
  belongs_to :album, :polymorphic => true
  belongs_to :photo, :polymorphic => true
end
