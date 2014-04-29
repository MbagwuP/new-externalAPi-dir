module Probes
  class MemCache < Probes::Probe

    def probe
      if(HealthCheck.app_setting.memcached_server)
        url = HealthCheck.app_setting.memcached_server
        begin
          cache = Dalli::Client.new(url, :expires_in => 3600)
          cache.set("testvalue", "12346", 20)
          newvalue = cache.get("testvalue")
          cacheUp = true if (newvalue == "12346")
        rescue Exception => e
          cacheUp = false
        end
        record(*["MemCache", cacheUp, cacheUp ? "MemCache is active." : "MemCache is down."])
        self
      end
    end
  end
end
