module Probes
  class Redis < Probes::Probe
    def probe
      value = {up: nil}
      begin
        if defined?(::Resque)
          redis = ::Resque.redis
          value[:up] = redis.ping
        elsif defined?(::Redis)
          redis = ::Redis.new
          value[:up] = redis.ping
        end
      rescue => e
        err_msg = e.message
      end
      is_up = value[:up] == "PONG"
      record(*["Redis", is_up, is_up ? "Redis is available." : err_msg])
      self
    end
  end
end
