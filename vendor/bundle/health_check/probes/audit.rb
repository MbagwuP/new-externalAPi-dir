module Probes
  class Audit < Probes::Probe

    # Setup logger and default logging level
    Log4r::StderrOutputter.new('console')
    Log4r::FileOutputter.new('logfile', :filename => 'log/external_api.log', :trunc => false)
    LOG = Log4r::Logger.new('logger')
    LOG.add('console', 'logfile')


    LOG.debug("In The Loop")
    LOG.debug(CareCloud::AuditRecord)
    def probe
      if defined?(CareCloud::AuditRecord)
        is_up = false
        begin
          auudtevents = CareCloud::AuditRecord.where(:uuid => 0).first
          is_up = true
        rescue => e
          is_up = false
        end
        record(*["Audit Service", is_up, is_up ? "Audit Service is active." : "Audit Service is down"])
      end
    self
    end

  end
end