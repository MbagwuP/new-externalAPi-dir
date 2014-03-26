require "c_cloud_dms_client/version"
require "c_cloud_http_client"

module CCloudDmsClient
  class DocumentApi
    include ::CCloudHttpClient

    class << self
      attr_accessor :endpoint
    end

    def self.upload(file_path, token, params={})
      file = File.new(file_path, 'rb')
      options = params.merge(file: file, token: token)
      res = JSON.parse(post("#{self.endpoint}/documents", options)).symbolize_keys!
      res
    end

    #def self.health_check
    #  JSON.parse(RestClient.get("#{self.endpoint}/health_check.json"))
    #end

    def self.health_check
      conn = RestClient.get("#{self.endpoint}/api/explorer")
      response = conn.code ? "200" : nil if conn.code
      response
    end

  end
end
