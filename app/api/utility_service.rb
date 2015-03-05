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


  get '/v1/nature_of_visits?' do

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)

    #http://localservices.carecloud.local:3000/public/businesses/1/providers.json?token=
    #nature_of_visits/list_by_business_entity/:business_entity_id(.:format)
    nature_of_visit_url = ''
    nature_of_visit_url << API_SVC_URL
    nature_of_visit_url << 'nature_of_visits/list_by_business_entity/'
    nature_of_visit_url << business_entity
    nature_of_visit_url << '.json?token='
    nature_of_visit_url << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(nature_of_visit_url)
    rescue => e
      begin
        errmsg = "Nature Of Visit Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    data = []
    parsed = JSON.parse(response.body)
    parsed.each do |x|
        filter_nov = {}
        filter_nov['id'] = x['nature_of_visit']['id']
        filter_nov['name'] = x['nature_of_visit']['name']
        filter_nov['description'] = x['nature_of_visit']['description']
        data.push filter_nov
      end
    body(data.to_json)
    status HTTP_OK

  end



end