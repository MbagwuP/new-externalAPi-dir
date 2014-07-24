module Probes
  class Dms < Probes::Probe
    def probe
      a = 1
        value = {up: nil}

          resp = RestClient.get("#{ApiService::SVC_URLS["api_internal_doc_srv_upld_url"]}/health_check")
          parsed = JSON.parse(resp.body)
          
          if parsed['service_status'] == 'up'
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
      self
    end
  end
end
