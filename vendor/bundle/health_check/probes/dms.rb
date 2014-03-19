module Probes
  class Dms < Probes::Probe
    def probe
      if defined?(CCloudDmsClient::DocumentApi)
        value = {up: nil}
        begin
          health = CCloudDmsClient::DocumentApi.health_check 
          value[:up] = health["service_status"]
        rescue => e
          err_msg = case e.class.to_s
                    when "Errno::ECONNREFUSED"
                      "Connection Refused"
                    when "RestClient::ResourceNotFound"
                      "Health check not configured."
                    else
                      e.message
                    end
        end
        is_up = value[:up] == "up"
        record(*["Document Management Service", is_up, is_up ? "DMS is active." : err_msg])
      end
      self
    end
  end
end
