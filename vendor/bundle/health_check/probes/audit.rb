module Probes
  class Audit < Probes::Probe
    def probe
      if defined?(CareCloud::AuditRecord)
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