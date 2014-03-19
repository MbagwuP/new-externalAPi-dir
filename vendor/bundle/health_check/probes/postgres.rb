module Probes
  class Postgres < Probes::Probe
    def probe
      if defined?(ActiveRecord)
        value = {up: nil}
        begin
          value[:up] = ActiveRecord::Base.connection.active? 
        rescue => e
          err_msg = case e.class.to_s
                    when "PG::ConnectionBad" 
                      "Unable to connect: Check database configurations."
                    else
                      e.message
                    end
        end
        is_up = value[:up] == true
        record(*["Postgres Database", is_up, is_up ? "Database connection is active." : err_msg])
      end
      self
    end
  end
end
