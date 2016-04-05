class ApiService << Sinatra::Base

  put 'v2/encounter_notes/:encounter_id/merge_transcriptions' do

    begin
      access_token, encounter_id = get_oauth_token, params[:encounter_id]
      request_body = get_request_JSON
      data  = CCAuth::OAuth2Client.new.authorization access_token

      merge_transcription_url = "#{ApiService::API_SVC_URL}encounter_notes/#{data[:scope][:business_entity_id]}"
      merge_transcription_url << "/encounter_id/#{encounter_id}/merge_transcriptions.json?token=#{access_token}"

      response = RestClient.put merge_transcription_url, request_body.to_json, :content_type => :json, extapikey: ApiService::APP_API_KEY
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