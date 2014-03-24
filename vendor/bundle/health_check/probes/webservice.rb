module Probes
  class Webservice < Probes::Probe

    def probe
      if(CCloudWebServices)
        conn = CCloudWebServices::WebService.health_check
        is_up = false
        is_up = true if conn == "200"
        err_msg = "Service is down"
        record(*["Service", is_up, is_up ? "Service is active." : err_msg])
        self
      end
    end
  end
end
