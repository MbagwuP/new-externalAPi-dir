module WebserviceResources
  class MaritalStatus
    extend Client::Webservices
      
    def self.values
      cache_key = "marital-status-codes"
      cache_retrieval(cache_key, :marital_status_codes_from_webservices)
    end

    def self.marital_status_codes_from_webservices
      marital_statuses = rescue_service_call('Marital Status Look Up',true) do
        RestClient.get(webservices_uri "people/list_all_marital_statuses.json", :api_key => ApiService::APP_API_KEY)
      end
      marital_statuses = JSON.parse marital_statuses
      marital_status_assembly = {}
      marital_statuses.each do |marital_status|
        marital_status_assembly['code'] = '' unless marital_status['marital_status']['code'].present?
        marital_status_assembly[marital_status['marital_status']['id']] = get_fhir_codes['marital_status'][marital_status['marital_status']['code']]
      end
      marital_status_assembly
    end
  end
end
