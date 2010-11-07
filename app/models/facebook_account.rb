class FacebookAccount < ActiveRecord::Base
  has_many :albums, :as => :owner, :dependent => :destroy


  def self.auth_url(root_url)
    "https://graph.facebook.com/oauth/authorize?client_id=#{FACEBOOK_TOKEN}&redirect_uri=#{root_url}accounts/facebook_callback&scope=user_photos,publish_stream,offline_access"
  end

  def self.oauth_exchange_url(root_url, code)
    "https://graph.facebook.com/oauth/access_token?client_id=#{FACEBOOK_TOKEN}&redirect_uri=#{root_url}accounts/facebook_callback&client_secret=#{FACEBOOK_SECRET}&code=#{CGI::escape code}"
  end

  def get_albums
    self.albums.destroy_all if self.albums
    
    #TODO: save primary image in database
    xml = get("https://graph.facebook.com/me/albums?client_id=#{FACEBOOK_TOKEN}&client_secret=#{FACEBOOK_SECRET}&access_token=#{CGI::escape self.token}")
    parsed = JSON.parse(xml.body)
    parsed["data"].each do |album|
      facebook_album = Album.new({:name => album['name'], :remote_id => album['id']})
      self.albums << facebook_album
    end
  end

  def get_images_for(album)
    album.photos.destroy_all if album.photos
    url = "https://graph.facebook.com/#{album.remote_id}/photos?access_token=#{CGI::escape self.token}"
    xml = get(url)
    parsed = JSON.parse(xml.body)
    parsed["data"].each do |photo|
      album.photos << Photo.new({:remote_id => photo['id'], :url => photo['source']})
    end
  end


  def new_photo(album, url)
    image_data = get(url).body # NOT a facebook url
#    POST TO FACEBOOK, as multipart

    params = [
          file_to_multipart('file', 'file.jpg', 'image/jpg', image_data)]

    boundary = '349832898984244898448024464570528145'
    query = params.collect { |p| '--' + boundary + "\r\n" + p }.join('') + "--" + boundary + "--\r\n"

    url = "https://graph.facebook.com/#{self.remote_id}/photos?access_token=#{CGI::escape self.token}"
    use_ssl = url.include? 'https'
    url = URI.parse(url)

    http = Net::HTTP.new(url.host, use_ssl ? 443 : nil)
    http.use_ssl = use_ssl
    res = http.post2("/#{album.remote_id}/photos?access_token=#{CGI::escape self.token}",
                query,
                "Content-type" => "multipart/form-data; boundary=" + boundary)



  end

  def provider
    "facebook"
  end

  private
  
  def get(url)
    use_ssl = url.include? 'https'
    url = URI.parse(url)

    path = url.query.blank? ? url.path : "#{url.path}?#{url.query}"

    http = Net::HTTP.new(url.host, use_ssl ? 443 : nil)
    http.use_ssl = use_ssl
    res = http.get(path)

    if res.code == '302'
      return get(res['location']) # follow redirects
    end
    res
  end

  def file_to_multipart(key, filename, mime_type, content)
    "Content-Disposition: form-data; name=\"#{CGI::escape(key)}\"; filename=\"#{filename}\"\r\n" +
          "Content-Transfer-Encoding: binary\r\n" +
          "Content-Type: #{mime_type}\r\n" +
          "\r\n" +
          "#{content}\r\n"
  end

end
