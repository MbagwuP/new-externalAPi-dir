module Probes
  class Dms < Probes::Probe
    def probe
      a = 1
      if defined?(HealthCheck.app_setting.dms_server)
        value = {up: nil}

          health = RestClient.get("#{HealthCheck.app_setting.dms_server}/api/explorer")
          if health.code == 200
             is_up = true
          else
             is_up = false
          end
        #begin
        #rescue => e
        #  err_msg = case e.class.to_s
        #            when "Errno::ECONNREFUSED"
        #              "Connection Refused"
        #            when "RestClient::ResourceNotFound"
        #              "Health check not configured."
        #            else
        #              e.message
        #            end
        #end
        record(*["Document Management Service", is_up, is_up ? "DMS is active." : "DMS is down"])
      end
      self
    end
  end
end
