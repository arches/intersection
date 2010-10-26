class PageController < ApplicationController
  def index
    @accounts = []
    flickr_account = FlickrAccount.find_by_id(session[:flickr_account_id])
    facebook_account = FacebookAccount.find_by_id(session[:facebook_account_id])
    if flickr_account
      @accounts << flickr_account
      if flickr_account.albums.nil? or flickr_account.albums.length == 0
        flickr_account.get_albums
      end
    else
      session[:flickr_account_id] = nil
    end
    if facebook_account
      @accounts << facebook_account
      if facebook_account.albums.nil? or facebook_account.albums.length == 0
        facebook_account.get_albums
      end
    else
      session[:facebook_account_id] = nil
    end
  end
  
  def load_album_images
    album = Album.find(params[:id])
    album.owner.get_images_for(album)
    respond_to do |format|
      format.js do
        render :text => album.photos.to_json
      end
    end
  end
end
