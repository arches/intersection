require 'rubygems'
require 'mime/types'
require 'net/http'
require 'cgi'

module Multipart
  class Param
    attr_accessor :k, :v

    def initialize(k, v)
      @k = k
      @v = v
    end

    def to_multipart
      "Content-Disposition: form-data; name=\"#{CGI::escape(k)}\"\r\n\r\n#{v}\r\n"
    end
  end

  class UrlParam
    attr_accessor :k, :v

    def initialize(k, v)
      @k        = k
      @v        = v
      @filename = v[v.rindex("/")+1..-1]  # pull the filename out of the url
    end

    def to_multipart
      image_data = get(@v).body

      "Content-Disposition: form-data; name=\"#{CGI::escape(k)}\"; filename=\"#{@filename}\"\r\n" +
            "Content-Transfer-Encoding: binary\r\n" +
            "Content-Type: #{MIME::Types.type_for(@filename)}\r\n\r\n" + image_data + "\r\n"
    end

    private

    def get(url)
#      ssl = (url.index("https") == 0)
      url = URI.parse(url)

      path = (url.query.nil? or url.query.empty?) ? url.path : "#{url.path}?#{url.query}"

      http = Net::HTTP.new(url.host)#, ssl ? 443 : nil)
#      http.use_ssl = ssl
      res = http.get(path)

      if res.code == '302'
        return get(res['location']) # follow redirects
      end
      res
    end

  end

  class FileParam
    attr_accessor :k, :filename, :content

    def initialize(k, filename, content)
      @k        = k
      @filename = filename
      @content  = content
    end

    def to_multipart
      "Content-Disposition: form-data; name=\"#{CGI::escape(k)}\"; filename=\"#{filename}\"\r\n" +
            "Content-Transfer-Encoding: binary\r\n" +
            "Content-Type: #{MIME::Types.type_for(@filename)}\r\n\r\n" + content + "\r\n"
    end
  end

  class Post
    BOUNDARY = 'flickrrocks-aaaaaabbbb0000'
    HEADER   = {"Content-type" => "multipart/form-data, boundary=" + BOUNDARY + " "}

    def prepare_query (params)
      fp    = []
      params.each do |k, v|
        if v.respond_to?(:read)
          fp.push(FileParam.new(k.to_s, v.path, v.read))  # to_s in case we got symbols
        elsif v.to_s.index("http") == 0
          fp.push(UrlParam.new(k.to_s, v))
        else
          fp.push(Param.new(k.to_s, v))
        end
      end
      query = fp.collect { |p| "--" + BOUNDARY + "\r\n" + p.to_multipart }.join("") + "--" + BOUNDARY + "--"
      return query, HEADER
    end
  end
end
