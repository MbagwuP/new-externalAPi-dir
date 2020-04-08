module EncounterNote
  class HomunculusSection
  
    def initialize(questions)
      @errors = {}
      @physical_abilities = format_pa(questions["physical_abilities"])
      @pain_and_overall_healths = format_poh(questions["pain_and_overall_healths"])
      validate
    end
    
    def run
      if valid?
        self.to_request_hash
      else 
        raise Error::InvalidRequestError.new(self.error_messages)
      end
    end 
    
    def validate
      if @physical_abilities.any?
        errors = []
        errors << "Invalid values" unless @physical_abilities.values.all? {|v| (v).between?(0,3)}
        errors << "Invalid section keys" unless @physical_abilities.keys == [*1..13].map(&:to_s)
        @errors.merge!({physical_abilities: errors.join(",")}) if errors.any?
      end 
      if @pain_and_overall_healths.any?
        errors = []
        errors << "Invalid section values. Values must be a positive number and 10 or less" unless @pain_and_overall_healths.values.all? {|v| (v.to_f).between?(0,10)}
        errors << "Invalid section values. Values must be whole or half numbers (.5)" if @pain_and_overall_healths.values.all? {|v| ((v.to_f*10)%5) > 0}
        errors << "Invalid section keys" unless [*(-2)..(-1)].map(&:to_s)== @pain_and_overall_healths.keys.reverse
        @errors.merge!({pain_and_overall_healths: errors.join(", ")}) if errors.any?
      end
    end 
    
    def format_poh(questions)
      questions.to_a.map { |pair| [("-" + pair.first), pair.last.to_f] }.to_h
    end
    
    def format_pa(questions)
      questions.to_a.map { |pair| [(pair.first.to_s), pair.last.to_i] }.to_h
    end
    
    def valid?
      @errors.empty?
    end
    
    def error_messages
      msg = ""
      @errors.each do |k,v|
        msg << "#{k.to_s}: #{v} "
      end
      msg
    end
    
    def to_request_hash
      hash = self.as_json 
      hash.delete("errors")
      hash
    end 
  
  end 
end 