require 'multipart'

class FlickrAccount < ActiveRecord::Base
  has_many :albums, :as => :owner, :dependent => :destroy

  API_BASE_URL = "http://api.flickr.com/services/"

  def initialize(xml)
    super
    if xml.code == "200"
      parsed = Crack::XML.parse(xml.body)
      self.remote_id = parsed["rsp"]["auth"]["user"]["nsid"]
      self.token = parsed["rsp"]["auth"]["token"]
    else
      raise "error getting flickr authToken"
    end
  end

  def self.auth_url
    self.flickr_url({"perms" => "delete"}, "auth")
  end

  def self.frob_url(frob)
    self.flickr_url({"method" => "flickr.auth.getToken", "frob" => frob})
  end

  def get_albums

    self.albums.destroy_all if self.albums # start from scratch

    # sets
    xml = get(self.flickr_url({"method" => "flickr.photosets.getList", "user_id" => self.remote_id}))
    parsed = Crack::XML.parse(xml.body)
    photosets = parsed["rsp"]["photosets"]["photoset"]
    unless photosets.class == Array
      photosets = [photosets]
    end
    photosets.each do |set|
      album = Album.new({:name => set["title"], :primary_photo_url => "http://farm#{set['farm']}.static.flickr.com/#{set['server']}/#{set['primary']}_#{set['secret']}.jpg"})
      album.create_flickr_album({:farm => set["farm"], :server => set["server"], :photoset_id => set["id"], :secret => set["secret"]})
      self.albums << album
      album.save!
    end

    # photostream
    album = Album.new({:name => "Photostream"})
    self.albums << album
    album.save!
  end

  def check_token
    xml = get(self.flickr_url({"method" => "flickr.auth.checkToken", "auth_token" => self.token}))
    parsed = Crack::XML.parse(xml.body)
    raise parsed.inspect.to_s
   end

  def get_images_for(album)
    album.photos.destroy_all if album.photos

    if (album.name == "Photostream")
      xml = get(self.flickr_url({"method" => "flickr.people.getPhotos", "user_id" => self.remote_id, "auth_token" => self.token}))
      parsed = Crack::XML.parse(xml.body)
      photos = parsed["rsp"]["photos"]["photo"]
    else
      xml = get(flickr_url({"method" => "flickr.photosets.getPhotos", "photoset_id" => album.flickr_album.photoset_id}))
      parsed = Crack::XML.parse(xml.body)
      photos = parsed["rsp"]["photoset"]["photo"]
    end

    unless photos.class == Array
      photos = [photos]
    end
    photos.each do |photo|
      pic = Photo.new({:url => "http://farm#{photo['farm']}.static.flickr.com/#{photo['server']}/#{photo['id']}_#{photo['secret']}.jpg",
                       :remote_id => [photo['farm'], photo['server'], photo['id'], photo['secret']].join(":")})
      album.photos << pic
    end


  end

  def new_photo(album, photo_url)

#    unless photo_url.include? "static.flickr.com"
      params = {}
      params['api_key'] = FLICKR_TOKEN
      params['auth_token'] = self.token
      params['api_sig'] = flickr_sign(params)

      url = self.flickr_url({}, "upload")
      use_ssl = url.include? 'https'
      url = URI.parse(url)
      path = url.query.blank? ? url.path : "#{url.path}?#{url.query}"

      # can't add the photo until after we make the url, we don't want it in the query string
      params['photo'] = photo_url
      mp = Multipart::Post.new
      query, headers = mp.prepare_query(params)

      xml = nil
      Net::HTTP.new(url.host, url.port).start do |http|
        xml = http.post(url.path, query, headers)
      end
      parsed = Crack::XML.parse(xml.body)
      photo_id = parsed["rsp"]["photoid"]
#    end

    # if we got a photo ID back, add it to the specified photoset
    xml = get(self.flickr_url({"method" => "flickr.photosets.addPhoto", "photoset_id" => album.flickr_album.photoset_id, "photo_id" => photo_id, 'auth_token' => self.token}))
  end

  def self.flickr_sign(arg_hash)
    arg_list = []
    arg_hash.keys.sort.each do |key|
      arg_list << key
      arg_list << arg_hash[key]
    end
    Digest::MD5.hexdigest("#{FLICKR_SECRET}#{arg_list.join()}")
  end

  def self.flickr_url(arg_hash, endpoint = "rest")
    arg_hash.merge!({"api_key" => FLICKR_TOKEN})
    arg_list = []
    arg_hash.each do |key, value|
      arg_list << "#{key}=#{value}"
    end
    "#{API_BASE_URL}#{endpoint}/?&api_sig=#{self.flickr_sign(arg_hash)}&#{arg_list.join('&')}"
  end

  def flickr_sign(arg_hash)
    arg_list = []
    arg_hash.keys.sort.each do |key|
      arg_list << key
      arg_list << arg_hash[key]
    end
    Digest::MD5.hexdigest("#{FLICKR_SECRET}#{arg_list.join()}")
  end

  def flickr_url(arg_hash, endpoint = "rest")
    arg_hash.merge!({"api_key" => FLICKR_TOKEN})
    arg_list = []
    arg_hash.each do |key, value|
      arg_list << "#{key}=#{value}"
    end
    "#{API_BASE_URL}#{endpoint}/?&api_sig=#{flickr_sign(arg_hash)}&#{arg_list.join('&')}"
  end

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

  def provider
    "flickr"
  end

  def file_to_multipart(key, filename, mime_type, content)
    "Content-Disposition: form-data; name=\"#{CGI::escape(key)}\"; filename=\"#{filename}\"\r\n" +
          "Content-Transfer-Encoding: binary\r\n" +
          "Content-Type: #{mime_type}\r\n" +
          "\r\n" +
          "#{content}\r\n"
  end
  
end
