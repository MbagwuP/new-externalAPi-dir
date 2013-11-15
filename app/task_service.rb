#
# File:       task_service.rb
#
#
# Version:    1.0


class ApiService < Sinatra::Base


  #  create a task for a patient
  #
  # POST /v1/tasks/<clinicianid#>/<patientid#>/create?authentication=<authenticationToken>
  #
  # Params definition
  # :patientid     - the patient identifier number
  # :clinicialid   - the clinician identifier number
  #
  # server action: Return status task creation
  # server response:
  # --> if pass found: 200, with pass data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if bad request: 400
  post '/v1/tasks/:clinicianid/:patientid/create?' do

    # Validate the input parameters
    validate_param(params[:patientid], PATIENT_REGEX, PATIENT_MAX_LEN)
    validate_param(params[:clinicianid], CASEMGR_REGEX, CASEMGR_MAX_LEN)
    patientid = params[:patientid]
    patientid.slice!(/^patient-/)

    casemanager_id = params[:clinicianid]
    patientid.slice!(/^user-/)

    # AuthenticationToken can be provided in the body of the request or as a GET parameter
    #api_svc_halt HTTP_NOT_AUTHORIZED, '{"error":"Authorizatoin Failed"}' if pass[:auth_token] != (params[:authentication] || get_auth_token)

    body("ok")

    status HTTP_CREATED

  end

end