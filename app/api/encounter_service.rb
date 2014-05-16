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
    patientid = params[:patient_id]
    patientid.slice!(/^patient-/)

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
end