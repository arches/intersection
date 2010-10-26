class AccountController < ApplicationController

  def reset
    session[:facebook_account_id] = nil
    session[:flickr_account_id] = nil
    FacebookAccount.destroy_all
    FlickrAccount.destroy_all
    redirect_to root_path
  end

  def check_flickr_token
    FlickrAccount.find(session[:flickr_account_id]).check_token
  end

  def new
    account = self.send("new_#{params[:provider]}_account")
  end

  def new_flickr_account
    redirect_to FlickrAccount.auth_url
  end

  def flickr_callback
    xml = get(FlickrAccount.frob_url(params[:frob]))
    @account = FlickrAccount.create(xml)
    @account.save
    session[:flickr_account_id] = @account.id
    redirect_to root_path
  end

  def new_facebook_account
    redirect_to FacebookAccount.auth_url(root_url)
  end

  def facebook_callback
    resp = get(FacebookAccount.oauth_exchange_url(root_url, params[:code]))
    resp.body =~ /access_token=([^&]+)(?:&expires=(.*))?/
    @account = FacebookAccount.create({:token => $1})
    session[:facebook_account_id] = @account.id
    redirect_to root_path
  end

end
