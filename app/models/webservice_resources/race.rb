module WebserviceResources
  class Race
    extend Client::Webservices
      
    def self.values
      cache_key = "race-codes"
      cache_retrieval(cache_key, :race_codes_from_webservices)
    end

    def self.race_codes_from_webservices
      races = rescue_service_call('Race Look Up',true) do
        RestClient.get(webservices_uri "people/list_all_races.json", :api_key => ApiService::APP_API_KEY)
      end
      races = JSON.parse races

      races.map do |race|
        id = race['race']['id']
        code = race['race']['code'] || ''
        name = race['race']['name']

        body = {'values' => [code, id], 'default' => code, 'display' => name}

        [id, body]
      end.to_h
    end
  end
end
