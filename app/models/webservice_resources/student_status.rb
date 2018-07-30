module WebserviceResources
  class StudentStatus
    extend Client::Webservices
      
    def self.values
      cache_key = "student-status-codes"
      cache_retrieval(cache_key, :student_status_codes_from_webservices)
    end

    def self.student_status_codes_from_webservices
      student_statuses = rescue_service_call('Student Status Look Up',true) do
        RestClient.get(webservices_uri "people/list_all_student_statuses.json", :api_key => ApiService::APP_API_KEY)
      end
      student_statuses = JSON.parse student_statuses
      student_statuses_assembly = {}
      student_statuses.each do |student_status|
        student_status['code'] = '' unless student_status['student_status']['code'].present?
        student_status_assembly = {}
        student_status_assembly['values'] = [student_status['student_status']['code'], student_status['student_status']['id']]
        student_status_assembly['default'] = student_status['student_status']['code']
        student_status_assembly['display'] = student_status['student_status']['name']
        student_statuses_assembly[student_status['student_status']['id']] = student_status_assembly
      end
      student_statuses_assembly
    end
  end
end
