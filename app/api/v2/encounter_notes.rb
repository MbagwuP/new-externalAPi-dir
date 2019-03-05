class ApiService < Sinatra::Base

  put '/v2/encounter_notes/:encounter_id/merge_transcriptions' do

    begin
      encounter_id = params[:encounter_id]
      request_body = get_request_JSON

      merge_transcription_uri = "encounter_notes/#{current_business_entity}/encounter_id/#{encounter_id}/merge_transcriptions.json"

      response = RestClient.put webservices_uri(merge_transcription_uri, token: escaped_oauth_token), request_body.to_json, :content_type => :json, extapikey: ApiService::APP_API_KEY
    rescue => e
      begin
        errmsg = "Merge transcriptions failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    parsed_response = JSON.parse response.body
    body(parsed_response.to_json); status HTTP_OK

  end
  
  get '/v2/appointments/:appointment_id/encounter_note_templates' do
    path = (request.content_type == "application/xml") ?  "encounter_note_templates.xml" : "encounter_note_templates.json"

    ent_url = webservices_uri(path, {token: escaped_oauth_token, appointment_id: params[:appointment_id], business_entity_id: current_business_entity})
    
    resp = rescue_service_call('Appointment Note Template',true) do
      RestClient.get(ent_url, api_key: APP_API_KEY)
    end
    resp  #resp is either json or xml
  end
  
end