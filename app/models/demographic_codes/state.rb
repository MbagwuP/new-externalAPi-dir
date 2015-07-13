module DemographicCodes
  class State < DemographicCode
    def self.values
      cache_key = "state-codes"
      return cache_retrieval(cache_key, :state_codes_from_webservices)
    end

    def self.state_codes_from_webservices
      states = make_service_call 'State Look Up' do
        RestClient.get(webservices_uri "addresses/list_all_states.json", :api_key => ApiService::APP_API_KEY)
      end
      states = JSON.parse states
      states_assembly = {}
      states['states'].each do |state|
        state['name'] = '' unless state['name'].present?
        state_assembly = {}
        state_assembly['values'] = [state['name'], state['id']]
        state_assembly['default'] = state['name']
        state_assembly['display'] = state['name']
        states_assembly[state['id']] = state_assembly
      end
      return states_assembly
    end
  end
end
