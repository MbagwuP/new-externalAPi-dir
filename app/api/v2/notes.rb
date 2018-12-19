class ApiService < Sinatra::Base
  
  #/v2/appointments/:appointment_id/notes
  #/v2/appointments/:appointment_id/note
  post /\/v2\/appointments\/(?<appointment_id>([a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}))\/(note|notes)$/ do
    begin
      request_body = get_request_JSON
      
      api_svc_halt HTTP_BAD_REQUEST, '{error: Missing required Note text.}' if request_body['text'].blank?
      appointment_guid_check(params['appointment_id'])
      request_body['appointment_id'] = params['appointment_id']
      create_note_trigger_list(request_body)

      urlnote = webservices_uri "appointment_notes.json", token: escaped_oauth_token
      resp = rescue_service_call 'Create Apointment Note',true do
        RestClient.post(urlnote, request_body, :api_key => APP_API_KEY)
      end
    rescue => e
      begin
        exception = e.message
        errmsg = "Appointment Note Creation Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    @note = JSON.parse(resp)
    status HTTP_CREATED
    jbuilder :show_note
  end
  
  get '/v2/appointments/:appointment_id/notes' do
    begin
      urlnote = webservices_uri "appointment_notes.json", {token: escaped_oauth_token, appointment_id: params[:appointment_id]}
      resp = rescue_service_call 'List Apointment Notes',true do
        RestClient.get(urlnote, :api_key => APP_API_KEY)
      end
    rescue => e
      begin
        exception = e.message
        errmsg = "Appointment Note Lookup Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    notes = JSON.parse(resp)
    @notes = notes["notes"].select {|note| note["status"] == 'A'}
    status HTTP_OK
    jbuilder :list_notes
  end
  
  #/v2/appointments/:appointment_id/notes/:id
  #/v2/appointments/:appointment_id/note/:id
  put /\/v2\/appointments\/(?<appointment_id>([a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}))\/(note|notes)\/(?<id>([0-9]*))$/ do
    begin
      request_body = get_request_JSON
      
      api_svc_halt HTTP_BAD_REQUEST, '{error: Missing required Note text.}' if request_body['text'].blank?
      appointment_guid_check(params['appointment_id'])
      request_body['appointment_id'] = params['appointment_id']
      
      create_note_trigger_list(request_body)
    
      urlnote = webservices_uri "appointment_notes/#{params[:id]}.json", token: escaped_oauth_token
      resp = rescue_service_call 'Update Apointment Note',true do
        RestClient.put(urlnote, request_body, :api_key => APP_API_KEY)
      end
    rescue => e
      begin
        exception = e.message
        errmsg = "Appointment Note Creation Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    @note = JSON.parse(resp)
    status HTTP_CREATED
    jbuilder :show_note
  end
  
  #/v2/patients/:patient_id/notes
  #/v2/patients/:patient_id/note
  post /\/v2\/patients\/(?<patient_id>([a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}))\/(note|notes)$/ do
    begin
      request_body = get_request_JSON
      
      api_svc_halt HTTP_BAD_REQUEST, '{error: Missing required Note text.}' if request_body['text'].blank?
      patient_guid_check(params['patient_id'])
      request_body['patient_id'] = params['patient_id']
      
      create_note_trigger_list(request_body)
      
      urlnote = webservices_uri "patient_notes.json", token: escaped_oauth_token
      resp = rescue_service_call 'Create Patient Note',true do
        RestClient.post(urlnote, request_body, :api_key => APP_API_KEY)
      end
    rescue => e
      begin
        exception = e.message
        errmsg = "Patient Note Creation Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    @note = JSON.parse(resp)
    status HTTP_CREATED
    jbuilder :show_note
  end
  
  get '/v2/patients/:patient_id/notes' do
    begin
      urlnote = webservices_uri "patient_notes.json", { token: escaped_oauth_token, patient_id: params[:patient_id] }
      resp = rescue_service_call 'List Patient Notes',true do
        RestClient.get(urlnote, :api_key => APP_API_KEY)
      end
    rescue => e
      begin
        exception = e.message
        errmsg = "Patient Note Lookup Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    notes = JSON.parse(resp)
    @notes = notes["notes"].select {|note| note["status"] == 'A'}
    status HTTP_OK
    jbuilder :list_notes
  end
  
  #/v2/patients/:patient_id/notes/:id
  #/v2/patients/:patient_id/note/:id
  put /\/v2\/patients\/(?<patient_id>([a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}))\/(note|notes)\/(?<id>([0-9]*))$/ do
    begin
      request_body = get_request_JSON
      
      api_svc_halt HTTP_BAD_REQUEST, '{error: Missing required Note text.}' if request_body['text'].blank?
      patient_guid_check(params['patient_id'])
      request_body['patient_id'] = params['patient_id']
      
      create_note_trigger_list(request_body)
      
      urlnote = webservices_uri "patient_notes/#{params[:id]}.json", token: escaped_oauth_token
      resp = rescue_service_call 'Update Patient Note',true do
        RestClient.put(urlnote, request_body, :api_key => APP_API_KEY)
      end
    rescue => e
      begin
        exception = e.message
        errmsg = "Patient Note Update Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    @note = JSON.parse(resp)
    status HTTP_CREATED
    jbuilder :show_note
  end
  
  private 

  def create_note_trigger_list(request_body)
    if request_body['note_trigger']
      request_body['note_trigger']['actions'].map! do |action|
        id = WebserviceResources::Converter.code_to_cc_id(WebserviceResources::NoteTrigger, action)
        api_svc_halt HTTP_BAD_REQUEST, '{error: Invalid action code.}' if id.blank?
        id
      end
      # if "expires_at" is blank or null then trigger expires_at=never
      # added the "noon hack" to prevent any timezone issues in CC UI
      expires_at = request_body['note_trigger']['expires_at']
      request_body['note_trigger']['expires_at'] = expires_at.blank? ? nil : expires_at +"T12:00"
    end
    request_body
  end
  
end  