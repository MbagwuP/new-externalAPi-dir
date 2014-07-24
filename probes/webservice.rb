module Probes
  class Webservice < Probes::Probe
    def probe
        begin
        conn = RestClient.get("#{ApiService::SVC_URLS["api_internal_svc_url"]}system/status_check")
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
