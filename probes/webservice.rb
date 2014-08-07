module Probes
  class Webservice < Probes::Probe
    def probe
        begin
        is_up = false
        conn = RestClient.get("#{ApiService::SVC_URLS["api_internal_svc_url"]}health_check")
        status = JSON.parse(conn)
        is_up = true if status["service_status"] == 'up'
        rescue
          is_up = false
        end
        err_msg = "Service is down"
        record(*["Web Service", is_up, is_up ? "Web Service is active." : err_msg])
        self
    end
  end
end
