module Probes
  class Webservice < Probes::Probe
    def probe
      if HealthCheck.app_setting.api_url
        begin
        conn = RestClient.get("#{HealthCheck.app_setting.api_url}system/status_check")
          is_up = true if conn.code== 200
        rescue
          is_up = false
        end
        err_msg = "Service is down"
        record(*["Web Service", is_up, is_up ? "Web Service is active." : err_msg])
        self
      end
    end
  end
end
