module Probes
  class Mongo < Probes::Probe
    def probe
      value = {up: nil}
      begin
        value[:up] = if defined?(MongoMapper)
                       ping = MongoMapper.connection.ping
                       ping["ok"]
                     elsif defined?(Mongoid)
                       Mongoid.default_session.command(ping: 1)
                     else
                       {}
                     end
      rescue => e
        err_msg = e.message
      end
      is_up = value[:up] == 1.0
      record(*["Mongo", is_up, is_up ? "Mongo connection is active." : err_msg])
      self
    end
  end
end
