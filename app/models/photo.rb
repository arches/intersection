class Photo < ActiveRecord::Base
  belongs_to :album
  has_one :flickr_info, :dependent => :destroy
end
