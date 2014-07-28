module Probes
  class CcAuth < Probes::Probe
    def probe
        begin
        conn = RestClient.get("#{ApiService::CCAuth.endpoint}/ping")
          is_up = true if conn.code== 200
        rescue
          is_up = false
        end
        err_msg = "Service is down"
        record(*["CCAuth Service", is_up, is_up ? "CCAuth Service is active." : err_msg])
        self
    end
  end
end