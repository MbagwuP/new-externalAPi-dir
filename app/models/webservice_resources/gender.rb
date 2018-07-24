module WebserviceResources
  class Gender
    extend Client::Webservices
      
    def self.values
      cache_key = "gender-codes"
      cache_retrieval(cache_key, :gender_codes_from_webservices)
    end

    def self.gender_codes_from_webservices
      genders = rescue_service_call('Gender Look Up',true) do
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
    
    def self.map_fhir_to_cc_gender_codes(gender_code)
      code = gender_code.try(:upcase)
      return code if code.match(/^(M|F|U)$/)
      case code
      when 'MALE'
          'M'
        when 'FEMALE'
          'F' 
        when 'UNKNOWN'
          'U'
        else
         code
      end
    end
    
  end
end
