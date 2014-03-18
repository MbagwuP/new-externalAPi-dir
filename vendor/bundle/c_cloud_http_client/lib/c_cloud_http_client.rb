require "c_cloud_http_client/version"

module CCloudHttpClient

  class AuthenticationError < StandardError; end
  class AuthorizationError < StandardError; end
  class InternalServerError < StandardError; end

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def post(resource_uri, params={})
      RestClient.post resource_uri, params do |response, request, result, &block|
        response_handler(response, request, result, &block)
      end
    end

    def response_handler(response, request, result, &block)
      case response.code
      when 200..207
        response
      when 400
        puts "response Error: #{response}"
        if auth_failed?(response)
          raise AuthenticationError, response
        else
          response.return!(request, result, &block)
        end
      when 403
        puts "response Error: #{response}"
        raise AuthorizationError, response
      when 404..422
        puts "response Error: #{response}"
        response.return!(request, result, &block)
      else
        puts "response Error: #{response}"
        response.return!(request, result, &block)
      end
    end

    def auth_failed?(response)
      response =~ /Failed Authentication/
    end

  end
end
