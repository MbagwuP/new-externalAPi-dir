module Probes
  class MemCache < Probes::Probe

    def probe
      config_path = Dir.pwd + "/config/settings.yml"
      config = YAML.load(File.open(config_path))[ENV['RACK_ENV']]
      cache_url = config['memcache_servers']

      if(cache_url)
        begin
          cache = Dalli::Client.new(cache_url, :expires_in => 3600)
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
