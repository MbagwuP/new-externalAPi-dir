module WebserviceResources
  class Country
    extend Client::Webservices
    
    def self.values
      cache_key = "country-codes"
      cache_retrieval(cache_key, :country_codes_from_webservices)
    end

    def self.country_codes_from_webservices
      countries = rescue_service_call('Country Look Up',true) do
        request = RestClient::Request.new(url: webservices_uri('addresses/list_all_countries.json'), method: :get, headers: {api_key: ApiService::APP_API_KEY})
        CCAuth::InternalService::Request.sign!(request).execute
      end
      countries = JSON.parse countries
      countries_assembly = {}
      countries = countries.map{|x| x['country']}
      countries.each do |country|
        country['iso3'] = '' unless country['iso3'].present?
        country_assembly = {}
        country_assembly['values'] = [country['iso3'], country['id']]
        country_assembly['default'] = country['iso3']
        country_assembly['display'] = country['iso3']
        countries_assembly[country['id']] = country_assembly
      end
      countries_assembly
    end
  end
end
