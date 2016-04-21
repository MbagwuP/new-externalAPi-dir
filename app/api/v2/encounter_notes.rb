class ApiService < Sinatra::Base

  put '/v2/encounter_notes/:encounter_id/merge_transcriptions' do

    
    begin
      encounter_id = params[:encounter_id]
      request_body = get_request_JSON

      merge_transcription_url = webservices_uri(
        "/encounter_notes/#{current_business_entity}/encounter_id/#{encounter_id}/merge_transcriptions.json",
        token: escaped_oauth_token
        )

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
end