require 'net/http'
require 'net/https'

class ApplicationController < ActionController::Base
  protect_from_forgery


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
end
