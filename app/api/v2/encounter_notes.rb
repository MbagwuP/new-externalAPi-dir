class ApiService < Sinatra::Base

  put '/v2/encounter_notes/:encounter_id/merge_transcriptions' do

    begin
      encounter_id = params[:encounter_id]
      request_body = get_request_JSON
      homunculus_section = request_body["homunculus"]
      
      if homunculus_section.present?
        raise Error::InvalidRequestError.new("appointment_id is required.") if params[:appointment_id].blank?
        request_body["homunculus"] = EncounterNote::HomunculusSection.new(homunculus_section).run
      end
      merge_transcription_uri = "encounter_notes/#{current_business_entity}/encounter_id/#{encounter_id}/merge_transcriptions.json"
      response = RestClient.put webservices_uri(merge_transcription_uri, {token: escaped_oauth_token, skip_create_sections: (params[:skip_create_sections] || false),appointment_id: params[:appointment_id]}), request_body.to_json, :content_type => :json, extapikey: ApiService::APP_API_KEY
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
    
    #WS mapping: encounter_note_content_items#find_by_id
    path = "encounter_note_content_items/default/find_by_id"
    path_and_format = (request.content_type == "application/xml") ?  "#{path}.xml" : "#{path}.json"

    enci_url = webservices_uri(path_and_format, {token: escaped_oauth_token, with_data: "true", lite: params[:lite], appointment_id: params[:appointment_id], business_entity_id: current_business_entity})
    
    resp = rescue_service_call('Encounter Note Template',true) do
      RestClient.get(enci_url, api_key: APP_API_KEY)
    end
    resp  #resp is either json or xml
  end
  
  # post /\/v2\/appointments\/(?<appointment_id>([a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}))\/(note|notes)$/ do
  post /\/v2\/appointments\/(?<appointment_id>([a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}))\/clinical_findings(|\/(?<id>([a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12})))$/ do  
    begin
      response = ClinicalFormResource.create(get_request_JSON.merge("appointment_id" => params[:appointment_id],"uuid" => params[:id]), current_business_entity, escaped_oauth_token)
    rescue => e
      begin
        exception = e.message
        api_svc_halt e.http_code, exception
      rescue 
        api_svc_halt HTTP_INTERNAL_ERROR, exception
      end
    end
    response["id"] = response.delete("uuid")
    response["business_entity_id"] = current_business_entity
    response.to_json
  end

  
end