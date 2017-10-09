module WebserviceResources
  class Ethnicity < WebserviceClient
    def self.values
      cache_key = "ethnicity-codes"
      return cache_retrieval(cache_key, :ethnicity_codes_from_webservices)
    end

    def self.ethnicity_codes_from_webservices
      ethnicities = make_service_call 'Ethnicity Look Up' do
        RestClient.get(webservices_uri "people/list_all_ethnicities.json", :api_key => ApiService::APP_API_KEY)
      end
      ethnicities = JSON.parse ethnicities
      ethnicity_assembly = {}
      ethnicities['ethnicities'].each do |ethnicity|
        ethnicity['code'] = '' unless ethnicity['code'].present?
        inner = {}
        inner['values']  = [ethnicity['code'], ethnicity['id']]
        inner['default'] = ethnicity['code']
        inner['display'] = ethnicity['name']
        ethnicity_assembly[ethnicity['id']] = inner
      end
      return ethnicity_assembly
    end
  end
end
