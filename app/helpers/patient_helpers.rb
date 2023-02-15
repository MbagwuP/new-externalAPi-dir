class ApiService < Sinatra::Base
  
  def patient_guid_check(id)
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Patient ID must be a valid GUID."}' unless id.is_guid?
  end
  
  def convert_demographic_codes!(request_body)
    patient = request_body['patient']
    #gender_code can take the CC code or fhir code
    patient["gender_code"] = WebserviceResources::Gender.map_fhir_to_cc_gender_codes(patient["gender_code"]) if patient["gender_code"]
    phones = request_body['phones']
    addresses = request_body['addresses']

    patient_ids = make_new_id_hash(patient)
    patient.merge!(patient_ids)
    patient.delete('primary_care_physician_id')
    
    if addresses.present?
      addresses.each do |address|
        find_and_replace_address_keys(address)
        address_ids = make_new_id_hash(address)
        address.merge!(address_ids)
      end
    end
    if phones.present?
      phones.each do |phone|
        find_and_replace_phone_type_key(phone)
        phone_ids = make_new_id_hash(phone)
        phone.merge!(phone_ids)
      end
    end
  end
  
  #needed for backwards capability
  def find_and_replace_address_keys(address)
    if address["state"].try(:match,/^\d+$/) # needed for update patient
      address["state_id"] = address.delete("state") 
    elsif address["state"].try(:match,/^[a-zA-Z]{2}$/) # needed for create patient
      address["state_code"] = address.delete("state")
    end
    if address["country_name"].try(:match,/^\d+$/) 
      address["country_id"] = address.delete("country_name") 
    elsif address["country_name"].try(:match,/^[a-zA-Z]{3}$/)
      address["country_code"] = address.delete("country_name") 
    end
  end
  
  def find_and_replace_phone_type_key(phone)
    if phone["phone_type_id"].try(:match,/^[a-zA-Z]+$/)
        phone["phone_type_code"] = phone.delete("phone_type_id") 
    end
  end
  
  def make_new_id_hash(orig_hash)
    id_hash = {}
    orig_hash.map do |key,value|
      if key.match(/(_code)\z/) && !key.match(/(zip_code)/)
      key_id = key.gsub(/(_code)\z/, "_id")
      id = code_converter(orig_hash,key,orig_hash.delete(key))
      id_hash[key_id] = id
     end
    end
    id_hash
  end
  
  def code_converter(obj, code, value)
    converter = WebserviceResources::Converter 
    code_class = WebserviceResources::Demographics.set_class(code)
    value = converter.code_to_cc_id(code_class, value)
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

      LOG.debug("url for patient: " + urlpatient)

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
  
  def validate_required_params(request_body)
    raise ArgumentError.new("Missing required parameters: first_name and/or last_name") if request_body["patient"]["first_name"].blank? || request_body["patient"]["last_name"].blank?
  end

end
