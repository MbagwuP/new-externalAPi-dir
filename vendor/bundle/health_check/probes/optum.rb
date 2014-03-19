module Probes
  class Optum < Probes::Probe
    def probe
      is_up = true
      err_msg = "Optum is fucked"
      record(*["Optum Service", is_up, is_up ? "Optum is active." : err_msg])
      self
    end
  end
end 
