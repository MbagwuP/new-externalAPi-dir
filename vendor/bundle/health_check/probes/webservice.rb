module Probes
  class Webservice < Probes::Probe
    def probe
      if(CCloudWebServices)
        is_up = false
        conn = CCloudWebServices::WebService.health_check
        is_up = true if conn== "200"
        err_msg = "Service is down"
        record(*["Web Service", is_up, is_up ? "Web Service is active." : err_msg])
        self
      end
    end
  end
end
