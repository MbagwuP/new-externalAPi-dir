module WebserviceResources
  class Race < WebserviceClient
    def self.values
      cache_key = "race-codes"
      cache_retrieval(cache_key, :race_codes_from_webservices)
    end

    def self.race_codes_from_webservices
      races = make_service_call 'Race Look Up' do
        RestClient.get(webservices_uri "people/list_all_races.json", :api_key => ApiService::APP_API_KEY)
      end
      races = JSON.parse races
      race_assembly = {}
      races.each do |race|
        race['race']['code'] = '' unless race['race']['code'].present?
        race_assembly[race['race']['id']] = get_fhir_codes['race'][race['race']['code']]
      end
      race_assembly
    end
  end
end
