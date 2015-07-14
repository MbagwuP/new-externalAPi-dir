module DemographicCodes
  class EmploymentStatus < DemographicCode
    def self.values
      cache_key = "employment-status"
      return cache_retrieval(cache_key, :employment_status_codes_from_webservices)
    end

    def self.employment_status_codes_from_webservices
      employment_statuses = make_service_call 'Employment Status Look Up' do
        RestClient.get(webservices_uri "people/list_all_employment_statuses.json", :api_key => ApiService::APP_API_KEY)
      end
      employment_statuses = JSON.parse employment_statuses
      employment_statuses_assembly = {}
      employment_statuses.each do |employment_status|
        employment_status['employment_status']['code'] = '' unless employment_status['employment_status']['code'].present?
        employment_status_assembly = {}
        employment_status_assembly['values'] = [employment_status['employment_status']['code'], employment_status['employment_status']['id']]
        employment_status_assembly['default'] = employment_status['employment_status']['code']
        employment_status_assembly['display'] = employment_status['employment_status']['name']
        employment_statuses_assembly[employment_status['employment_status']['id']] = employment_status_assembly
      end
      return employment_statuses_assembly
    end
  end
end
