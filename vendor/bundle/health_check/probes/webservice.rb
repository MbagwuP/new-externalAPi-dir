module Probes
  class Webservice < Probes::Probe
    def probe
      config_path = Dir.pwd + "/config/settings.yml"
      config = YAML.load(File.open(config_path))[ENV['RACK_ENV']]
      svc_url = config['api_internal_svc_url']
      if svc_url
        begin
        conn = RestClient.get("#{svc_url}/system/status_check")
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
