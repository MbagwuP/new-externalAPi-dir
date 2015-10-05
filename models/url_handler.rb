# copied from Auth Service

class UrlHandler

  attr_accessor :query_params

  def initialize url
    url           = CGI.unescape(url)
    @url          = strip_query_string_from_url(url)
    @query_params = query_params_hash_from_url(url)
  end

  def base_url
    uri = URI.parse @url
    "#{uri.scheme}://#{uri.host}"
  end

  def query_string
    @query_params.to_query
  end

  def to_s
    @url + '?' + query_string
  end

  def url_without_query_string
    @url
  end

  def self.same_base_url? first_url, second_url
    false if !valid_url? first_url
    false if !valid_url? second_url
    CareCloud::UrlHandler.new(first_url).base_url == CareCloud::UrlHandler.new(second_url).base_url
  end

  def self.valid_url? url
    !(url =~ URI::regexp(%w'http https')).nil?
  end

  def self.query_string_to_hash string
    Rack::Utils.parse_nested_query(string)
  end

  private

  def query_params_hash_from_url url
    query = URI.parse(URI.escape(url)).query
    Rack::Utils.parse_nested_query(query)
  end

  def strip_query_string_from_url url
    uri = URI.parse(URI.escape(url))
    uri.query = nil
    uri.to_s
  end

end
