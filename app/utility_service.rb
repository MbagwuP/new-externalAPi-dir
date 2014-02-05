#
# File:       utility_service.rb
#
# service to hold endpoints that do not fit other places
#
# Version:    1.0


class ApiService < Sinatra::Base


  # Log/audit data with CareCloud
  #
  # POST /log
  #
  # severity (CRITICAL, ERROR, WARN)
  # msg - Content
  post '/v1/logevent?' do

    # Validate the input parameters
    request_body = get_request_JSON

    severity_logged = SEVERITY_TYPE_LOG

    case request_body["severity"]
      when "CRITICAL"
        severity_logged = SEVERITY_TYPE_FATAL
      when "ERROR"
        severity_logged = SEVERITY_TYPE_ERROR
      when "WARN"
        severity_logged = SEVERITY_TYPE_WARN
      else
        severity_logged = SEVERITY_TYPE_LOG
    end

    #LOG.debug(request_body)

    msg = request_body["message"]

    auditoptions = {
        :ip => "#{request.ip}",
        :msg => "#{msg}"
    }

    audit_log(AUDIT_TYPE_OUTSIDE, severity_logged, auditoptions)

    status HTTP_CREATED

  end


end