## http_client

class ApiService < Sinatra::Base
# Rest Client usage
# docs: https://github.com/archiloque/rest-client
# for results code between 200 and 207 a RestClient::Response will be returned
# for results code 301, 302 or 307 the redirection will be followed if the request is a get or a head
# for result code 303 the redirection will be followed and the request transformed into a get
# for other cases a RestClient::Exception holding the Response will be raised,
# a specific exception class will be thrown for known error codes

  def get(resource_uri, params = {})
    RestClient.get resource_uri, {:params => params} do |response, request, result, &block|
      response_handler(response, request, result, &block)
    end
  end

  def delete(resource_uri, params = {})
    RestClient.delete resource_uri, {:params => params} do |response, request, result, &block|
      response_handler(response, request, result, &block)
    end
  end

  def post(resource_uri, params = {})
    RestClient.post resource_uri, params do |response, request, result, &block|
      response_handler(response, request, result, &block)
    end
  end

  def response_handler(response, request, result, &block)
    case response.code
      when 200..207
        response
      else
        LOG.debug "HTTP response code:#{response.code}"
        response.return!(request, result, &block)
    end
  end

end