module Probes
  class MemCache < Probes::Probe

    def probe

      if(ApiService.settings.cache)
        begin
          ApiService.settings.cache.set("testvalue", "12346", 20)
          newvalue = ApiService.settings.cache.get("testvalue")
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
