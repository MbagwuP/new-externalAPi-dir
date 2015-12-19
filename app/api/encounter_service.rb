#
# File:       encounter_service.rb
#
#
# Version:    1.0

class ApiService < Sinatra::Base
  get '/v1/encounters/:patient_id' do
    validate_param(params[:patient_id], PATIENT_REGEX, PATIENT_MAX_LEN)
    api_svc_halt HTTP_FORBIDDEN if params[:authentication] == nil
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)
    patient_id = params[:patient_id]
    patient_id.slice!(/^patient-/)
    patientid = get_internal_patient_id(patient_id, business_entity, pass_in_token)

      urlencounter = ''
      urlencounter << API_SVC_URL
      urlencounter << 'patients/'
      urlencounter << patientid
      urlencounter << '/encounters'
      urlencounter << '.json?token='
      urlencounter << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urlencounter)
    rescue => e
      begin
        errmsg = "Retrieving Patient Data Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)
    encounter_data = []
    if parsed['encounters']
       parsed['encounters'].each do |encounter|
         encounter_hash = {}
         encounter_hash["encounter_id"] = encounter['id']
         encounter_hash["date_of_service"] = encounter['date_of_service']
         encounter_hash['nature_of_visit'] = encounter['nature_of_visit']
         encounter_data << encounter_hash
       end

    end
    body(encounter_data.to_json)
    status HTTP_OK
  end



  put '/v1/encounter_notes/:encounter_id/merge_transcriptions' do

  request_body = get_request_JSON

  pass_in_token = CGI::unescape(params[:authentication])

  business_entity = get_business_entity(pass_in_token)

  encounter_id = params[:encounter_id]

    url_get_encounter_note = ''
    url_get_encounter_note << API_SVC_URL
    url_get_encounter_note << 'encounter_notes/'
    url_get_encounter_note << business_entity.to_s
    url_get_encounter_note << '/encounter_id/'
    url_get_encounter_note << encounter_id.to_s
    url_get_encounter_note << '/merge_transcriptions.json?token='
    url_get_encounter_note << CGI::escape(pass_in_token)

    begin
    response = RestClient.put(url_get_encounter_note,request_body.to_json, :content_type => :json)
    rescue => e
      begin
        api_svc_halt e.http_code, e.response.body
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, e.message
      end
    end

    body(response)
      
    status HTTP_OK


  end





end