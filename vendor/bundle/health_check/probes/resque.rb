module Probes
  class Resque < Probes::Probe
    def probe
      if defined?(::Resque)
        value = {up: nil}
        begin
          value[:up] = ::Resque.redis.ping
        rescue => e
          err_msg = e.message
        end
        is_up = value[:up] == "PONG"
        if is_up # Check if there are any failures today
          workers = ::Resque.workers.select { |w| w.queues.include? "report_job" } 
          msg = workers.length > 0 ? "#{workers.length} worker#{workers.length == 1 ? '' : 's'}" : "No active workers"
          record(*["Resque", workers.length > 0, msg])
        end
        self
      end
    end
  end
end
