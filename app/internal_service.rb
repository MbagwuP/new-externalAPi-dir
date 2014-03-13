#
# File:       internal_service.rb
#
#
# Version:    1.0

class ApiService < Sinatra::Base


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

    patient["appointment"] = apt.first

    LOG.debug(patient)
    body(patient.to_json)

    status HTTP_OK
  end







end