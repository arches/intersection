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
    if album.photos.nil? or album.photos.empty?
      album.owner.get_images_for(album)
    end
    respond_to do |format|
      format.js do
        render :text => album.photos.to_json
      end
    end
  end

  def move
    album = Album.find(params[:id])
    account = album.owner
    photo = Photo.find(params[:photo_id])
    account.new_photo(album, photo)
    album.photos.destroy_all  # force a refresh next time
    if account.provider == "flickr"
      account.albums.each do |album|
        if album.name == "Photostream"
          album.photos.destroy_all  # also refresh photostream for flickr
          break
        end
      end
    end
    render :text => "success!"
  end

  def refresh
    account = "#{params[:provider]}_account".camelize.constantize.find_by_id(session["#{params[:provider]}_account_id".to_sym])
    account.albums.destroy_all
    redirect_to root_path
  end

end
