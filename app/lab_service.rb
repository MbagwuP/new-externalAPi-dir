#
# File:       lab_service.rb
#
#
# Version:    1.0

class ApiService < Sinatra::Base


  #  lab inbound - pass through to transmit JSON from Mirth to Rails app
  #
  # POST /v1/lab/inbound
  #
  # server action: Return 200 if success, no content
  # server response:
  # --> if authenticated: 200
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  post '/v1/lab/inbound' do

    # Validate the input parameters
    request_body = get_request_JSON

    urllabinbound = ''
    urllabinbound << API_SVC_URL
    urllabinbound << 'labs/inboundrequest'

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