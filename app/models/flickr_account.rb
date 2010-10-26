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
      album = Album.new({:name => set["title"]})
      album.create_flickr_album({:farm => set["farm"], :server => set["server"], :remote_id => set["id"], :secret => set["secret"]})
      self.albums << album
      album.save!
      get_images_for(album)
    end

    # photostream
    album = Album.new({:name => "Photostream"})
    self.albums << album
    album.save!
  end

  def get_images_for(album)
    album.photos.destroy_all if album.photos

    if (album.name == "Photostream")
      # photostream
      xml = get(self.flickr_url({"method" => "flickr.people.getPhotos", "user_id" => self.remote_id}))
      parsed = Crack::XML.parse(xml.body)
      photos = parsed["rsp"]["photos"]
      unless photos.class == Array
        photos = [photos]
      end
      photos.each do |set|
        pic = Photo.new({:url => "http://farm#{photo['farm']}.static.flickr.com/#{photo['server']}/#{photo['id']}_#{photo['secret']}.jpg",
                         :remote_id => [photo['farm'], photo['server'], photo['id'], photo['secret']].join(":")})
        album.photos << pic
        pic.create_flickr_album({:farm => set["farm"], :server => set["server"], :remote_id => set["id"], :secret => set["secret"]})
        get_images_for(album)
      end
    else
      # sets
      xml = get(flickr_url({"method" => "flickr.photosets.getPhotos", "photoset_id" => album.flickr_album.photoset_id}))
      parsed = Crack::XML.parse(xml.body)
      photos = parsed["rsp"]["photoset"]["photo"]
      unless photos.class == Array
        photos = [photos]
      end
      photos.each do |photo|
        pic = Photo.new({:url => "http://farm#{photo['farm']}.static.flickr.com/#{photo['server']}/#{photo['id']}_#{photo['secret']}.jpg",
                         :remote_id => [photo['farm'], photo['server'], photo['id'], photo['secret']].join(":")})
        album.photos << pic
      end
    end

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

end
