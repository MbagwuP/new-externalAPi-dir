#
# File:       lab_service.rb
#
#
# Version:    1.0

class ApiService < Sinatra::Base


  #  lab inbound - add content
  #
  # POST /v1/lab/inbound
  #
  # server action: Return <..something..>
  # server response:
  # --> if authenticated: 200
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  post '/v1/lab/inbound' do

    # Validate the input parameters
    request_body = get_request_JSON

    ## TODO: authenticate with lab credentials

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    urllabinbound = ''
    urllabinbound << API_SVC_URL
    urllabinbound << 'labs/inboundrequest?token='
    urllabinbound << CGI::escape(params[:authentication])

    LOG.debug("url for lab inbound request: " + urllabinbound)

    resp = generate_http_request(urllabinbound, "", request_body.to_json, "POST", settings.labs_user, settings.labs_pass)

    LOG.debug(resp.body)
    response_code = map_response(resp.code)

    status HTTP_OK
    body("hello world - inbound")

  end


  post '/v1/lab/outbound' do

    status HTTP_OK
    body("hello world - outbound")

  end

end