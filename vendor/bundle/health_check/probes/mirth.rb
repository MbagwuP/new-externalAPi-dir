module Probes
  class Mirth < Probes::Probe
    def probe
      is_up = true
      err_msg = "Mirth is down"
      channels = []
      5.times { |i| channels << "channel #{i} status: up" }
      record(*["Mirth", is_up, is_up ? "Mirth is active." : err_msg, nil, channels])
      self
    end
  end
end 
