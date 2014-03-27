require "c_cloud_web_services/version"

module CCloudWebServices
  class WebService

    class << self
      attr_accessor :endpoint
    end

    def self.health_check
     begin
       conn = RestClient.get("#{self.endpoint}/system/status_check")
       response = conn.code ? "200" : nil if conn.code
       response
     rescue => e
       end
    end

  end
end
