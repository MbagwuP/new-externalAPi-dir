require "c_cloud_web_services/version"

module CCloudWebServices
  class WebService


    Log4r::StderrOutputter.new('console')
    Log4r::FileOutputter.new('logfile', :filename => 'log/external_api.log', :trunc => false)
    LOG = Log4r::Logger.new('logger')
    LOG.add('console', 'logfile')
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
