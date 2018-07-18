module WebserviceResources
  class EligibilityOutcome
    extend Client::Webservices  
    
    def self.values
      cache_key = "eligibility-outcomes"
      cache_retrieval(cache_key, :list_all)
    end
    
    def self.list_all
      url = webservices_uri "eligibility_outcomes.json"
      outcomes = rescue_service_call 'Eligibility Outcome Look Up' do 
        fetch_list(url)
      end
      format_list_for_converter(outcomes)
    end
    
    def self.format_list_for_converter(outcomes)
      outcomes_assembly = {}
      outcomes.each do |eo|
        outcome_assembly = {}
        outcome_assembly['values'] = [eo['eligibility_outcome']['code'], eo['eligibility_outcome']['id']]
        outcome_assembly['default'] = eo['eligibility_outcome']['code']
        outcome_assembly['display'] = eo['eligibility_outcome']['code']
        outcomes_assembly[eo['eligibility_outcome']['id']] = outcome_assembly
      end
      outcomes_assembly
    end

  end
end