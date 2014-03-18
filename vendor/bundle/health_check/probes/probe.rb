module Probes
  class Probe
    attr_accessor :records, :level

    def initialize
      @records = []
    end

    #~ [name, status, comment, level, details]
    def record(name, status, comment=nil, _level=nil, _details=nil)
      @records << [name.to_s, !!status, (comment || "").to_s, _level || @level, _details]
    end

    def clear
      @records = []
    end
  end
end
