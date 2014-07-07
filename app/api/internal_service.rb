#
# File:       internal_service.rb
#
#
# Version:    1.0

class ApiService < Sinatra::Base


  #used to get list of callbacks
  #notification_id = callback id
  #start_date = from date of notification lookup
  #end_date = end date of notification lookup
  #business_entity_id = BE
  #mirth_url = reprocess messages to mirth url.

  get '/v1/notifications/:notification_id/:start_date/:end_date/:business_entity_id' do
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)

    getcallbacks = ''
    getcallbacks << API_SVC_URL
    getcallbacks << 'notification_callbacks/'
    getcallbacks << params[:notification_id]
    getcallbacks << ".json?token="
    getcallbacks << CGI::escape(pass_in_token)

    begin
      callback = RestClient.get(getcallbacks)
    rescue => e
      begin
        errmsg = "Notification Callback Error - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    Exception.raise("Notification Callback Error") if callback.blank?

    callback_info = JSON.parse(callback.body)
    url = callback_info['notification_callback']['notification_callback_url']
    LOG.debug(url)

    urlcallbacks = ''
    urlcallbacks << API_SVC_URL
    urlcallbacks << 'notification_callbacks/'
    urlcallbacks << params[:start_date]
    urlcallbacks << "/"
    urlcallbacks << params[:end_date]
    urlcallbacks << '/id/'
    urlcallbacks << params[:notification_id]
    urlcallbacks << '/'
    urlcallbacks << business_entity
    urlcallbacks << ".json?token="
    urlcallbacks << CGI::escape(pass_in_token)
    LOG.debug(urlcallbacks)

    begin
      response = RestClient.get(urlcallbacks)
    rescue => e
      begin
        errmsg = "Notification Callback look up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)
    body(parsed.to_json)
    status HTTP_OK

  end

  #used to find notifications and reprocess callbacks
  #notification_id = callback id
  #start_date = from date of notification lookup
  #end_date = end date of notification lookup
  #business_entity_id = BE
  #mirth_url = reprocess messages to mirth url.

  get '/v1/reprocess/notifications/:notification_id/:start_date/:end_date/:business_entity_id' do
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)

    getcallbacks = ''
    getcallbacks << API_SVC_URL
    getcallbacks << 'notification_callbacks/'
    getcallbacks << params[:notification_id]
    getcallbacks << ".json?token="
    getcallbacks << CGI::escape(pass_in_token)

    LOG.debug("URL 1")

    begin
      callback = RestClient.get(getcallbacks)
    rescue => e
      begin
        errmsg = "Notification Callback Error - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    LOG.debug("URL 2")
    LOG.debug(callback)

    callback_info = JSON.parse(callback.body)
    url = callback_info['notification_callback']['notification_callback_url']
    LOG.debug(url)

    urlcallbacks = ''
    urlcallbacks << API_SVC_URL
    urlcallbacks << 'notification_callbacks/'
    urlcallbacks << params[:start_date]
    urlcallbacks << "/"
    urlcallbacks << params[:end_date]
    urlcallbacks << '/id/'
    urlcallbacks << params[:notification_id]
    urlcallbacks << ".json?token="
    urlcallbacks << CGI::escape(pass_in_token)
    LOG.debug(urlcallbacks)

    begin
      response = RestClient.get(urlcallbacks)
    rescue => e
      begin
        errmsg = "Notification Callback look up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)
    parsed.each do |audit|
      @temp_hash = {
          "event_raised" => "PatientUpdate",
          "event_type" => audit['audit']['audit_type_id'],
          "id" =>  audit['audit']['external_id'],
          "isnew" => false,
          "business" => audit['audit']['business_entity_id'],
          "status"=> "A"
      }
      @json_request = @temp_hash.to_json
      RestClient.post(url,@json_request, :content_type => :json)
    end
    body(parsed.to_json)
    status HTTP_OK
  end


  #get notification callbacks since a date
  #URL: v1/notification_callbacks/2013-12-30/85152eb3-0140-4812-9428-8ceee06a25bc?authentication=
  #params ex.
  #date = 2013-12-30
  #notification_callback id = 85152eb3-0140-4812-9428-8ceee06a25bc


  get '/v1/notification_callbacks/:date/:notification_id?' do
    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    business_entity = get_business_entity(pass_in_token)
    #LOG.debug(business_entity)

    urllocation = ''
    urllocation << API_SVC_URL
    urllocation << 'notification_callbacks/'
    urllocation << params[:date]
    urllocation << '/id/'
    urllocation << params[:notification_id]
    urllocation << ".json?token="
    urllocation << CGI::escape(pass_in_token)
    #LOG.debug(urllocation)

    begin
      response = RestClient.get(urllocation)
    rescue => e
      begin
        errmsg = "Notification Callback look up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end


    parsed = JSON.parse(response.body)

    body(parsed.to_json)

    status HTTP_OK
  end

  #used for interface for outbound SIU messages (HL7)
  get '/v1/internal/apt/outbound/:appointmentid/:business_entity?' do

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    appointmentid = params[:appointmentid]

    #http://localservices.carecloud.local/appointments/1/abcd93832/listbyexternalid.json?token=
    urlappt = ''
    urlappt << API_SVC_URL
    urlappt << 'appointments/'
    urlappt << params[:business_entity]
    urlappt << '/'
    urlappt << appointmentid
    urlappt << '/listbyexternalid2.json?token='
    urlappt << CGI::escape(pass_in_token)


    begin
      response = RestClient.get(urlappt)
    rescue => e
      begin
        errmsg = "Appointment Look up failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    apt = JSON.parse(response.body)
    LOG.debug(apt)
    patientid = apt['appointment']['patient_ext_id']

    urlpatient = ''
    urlpatient << API_SVC_URL
    urlpatient << 'businesses/'
    urlpatient << params[:business_entity]
    urlpatient << '/patients/'
    urlpatient <<  patientid
    urlpatient << '/externalid.json?token='
    urlpatient << CGI::escape(pass_in_token)
    urlpatient << '&do_full_export=true'

    begin
      resp = RestClient.get(urlpatient)
    rescue => e
      begin
        errmsg = "Patient Look up failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    patient = JSON.parse(resp.body)
    patient['id'] = patient['external_id']

    patient["appointment"] = apt

    LOG.debug(patient)
    body(patient.to_json)

    status HTTP_OK
  end







end