module Probes
  class Jasper < Probes::Probe
    def probe
      if defined?(CareCloud::Jasper)
        value = {up: nil}
        begin
          jasper = CareCloud::Jasper.new
          value[:up] = jasper.driver.operations.any?
        rescue => e
          err_msg = case e.class.to_s
                    when "Wasabi::Resolver::HTTPError" 
                      "Check Configuration: Authorization Error!" if e.message == "Error: 401"
                      "Service is Unavailable!" if e.message == "Error: 503"
                    else
                      e.message
                    end
        end
        is_up = value[:up] == true
        record(*["Jasper", is_up, is_up ? "Jasper service is active." : err_msg])
      end
      self
    end
  end
end
