class ApiService < Sinatra::Base
  
  def patient_guid_check(id)
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Patient ID must be a valid GUID."}' unless id.is_guid?
  end

  def convert_demographic_codes!(request_body)
    patient = request_body['patient']
    converter = WebserviceResources::Converter
    patient['gender_id'] = converter.code_to_cc_id(WebserviceResources::Gender, patient.delete('gender_code')) unless patient['gender_id'].present?
    patient['race_id'] = converter.code_to_cc_id(WebserviceResources::Race, patient.delete('race_code')) unless patient['race_id'].present?
    patient['marital_status_id'] = converter.code_to_cc_id(WebserviceResources::MaritalStatus, patient.delete('marital_status_code')) unless patient['marital_status_id'].present?
    patient['language_id'] = converter.code_to_cc_id(WebserviceResources::Language, patient.delete('language_code')) unless patient['language_id'].present? 
    patient['drivers_license_state_id'] = converter.code_to_cc_id(WebserviceResources::State, patient.delete('drivers_license_state_code')) unless patient['drivers_license_state_id'].present?
    patient['employment_status_id'] = converter.code_to_cc_id(WebserviceResources::EmploymentStatus, patient.delete('employment_status_code')) unless patient['employment_status_id'].present?
    patient['ethnicity_id'] = converter.code_to_cc_id(WebserviceResources::Ethnicity, patient.delete('ethnicity_code')) unless patient['ethnicity_id'].present?
    patient['student_status_id'] = converter.code_to_cc_id(WebserviceResources::StudentStatus, patient.delete('student_status_code')) unless patient['student_status_id'].present?
    patient.delete('primary_care_physician_id')
  end

    def get_internal_patient_id (patientid, business_entity_id, pass_in_token)

    pass_in_token = CGI::unescape(pass_in_token)

    if !is_this_numeric(patientid)

      urlpatient = ''
      urlpatient << API_SVC_URL
      urlpatient << 'businesses/'
      urlpatient << business_entity_id
      urlpatient << '/patients/'
      urlpatient << patientid
      urlpatient << '/externalid.json?token='
      urlpatient << CGI::escape(pass_in_token)

      #LOG.debug("url for patient: " + urlpatient)

      begin
        resp = RestClient.get(urlpatient)
      rescue => e
        begin
          errmsg = "Get Patient Failed - #{e.message}"
          api_svc_halt e.http_code, errmsg
        rescue
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end

      parsed = JSON.parse(resp.body)

      patientid = parsed["patient"]["id"].to_s

      #LOG.debug(patientid)

    end

    return patientid

  end

  def get_internal_patient_id_by_patient_number (patientid, business_entity_id, pass_in_token)

      pass_in_token = CGI::unescape(pass_in_token)
      urlpatient = "#{API_SVC_URL}businesses/#{business_entity_id}/patients/#{patientid}/othermeans.json?token=#{CGI::escape(pass_in_token)}"

      begin
        resp = RestClient.get(urlpatient)
      rescue => e
        begin
          errmsg = "Get Patient Failed - #{e.message}"
          api_svc_halt e.http_code, errmsg
        rescue
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end

      parsed = JSON.parse(resp.body)
      patientid = parsed["patient"]["id"].to_s
      return patientid
  end

  def get_patient_id_with_other_id (id, business_entity_id, pass_in_token)

    pass_in_token = CGI::unescape(pass_in_token)

    urlpatient = ''
    urlpatient << API_SVC_URL
    urlpatient << 'businesses/'
    urlpatient << business_entity_id
    urlpatient << '/patients/'
    urlpatient << id
    urlpatient << '/othermeans.json?token='
    urlpatient << CGI::escape(pass_in_token)

    #LOG.debug("url for patient: " + urlpatient)

    begin
      resp = RestClient.get(urlpatient)
    rescue => e
      begin
        errmsg = "Get patient id with other id Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(resp.body)

    patientid = parsed["patient"]["id"].to_s

    #LOG.debug(patientid)


    return patientid

  end

end
