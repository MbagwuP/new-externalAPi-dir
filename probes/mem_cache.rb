module Probes
  class MemCache < Probes::Probe

    def probe
        begin
          XAPI::Cache.set("testvalue", "12346", 20)
          newvalue = XAPI::Cache.get("testvalue")
          cacheUp  = true if (newvalue == "12346")
        rescue
          cacheUp = false
        end
        record(*["MemCache", cacheUp, cacheUp ? "MemCache is active." : "MemCache is down."])
        self
    end
  end
end
