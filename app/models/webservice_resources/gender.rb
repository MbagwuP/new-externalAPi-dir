module WebserviceResources
  class Gender < WebserviceClient
    def self.values
      cache_key = "gender-codes"
      cache_retrieval(cache_key, :gender_codes_from_webservices)
    end

    def self.gender_codes_from_webservices
      genders = make_service_call 'Gender Look Up' do
        RestClient.get(webservices_uri "people/list_all_genders.json", :api_key => ApiService::APP_API_KEY)
      end
      genders = JSON.parse genders
      gender_assembly = {}
      genders.each do |gender|
        gender['gender']['code'] = '' unless gender['gender']['code'].present?
        gender_assembly[gender['gender']['id']] = get_fhir_codes['gender'][gender['gender']['code']]
      end
      gender_assembly
    end
  end
end
