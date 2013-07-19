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

    passed_in_key = params[:key]
    passed_in_id = params[:id]

    # key determination
    current_date = DateTime.now()

    mirth_key = ''
    mirth_key << MIRTH_PRIVATE_KEY
    mirth_key << current_date.strftime("%Y%m%d")
    mirth_key << passed_in_id

    ##http://ruby-doc.org/stdlib-1.9.3/libdoc/digest/rdoc/Digest.html
    LOG.debug(passed_in_key)
    LOG.debug(mirth_key)

    h = Digest::SHA2.new << mirth_key
    LOG.debug(h.to_s)

    if passed_in_key != h.to_s

      auditoptions = {
          :ip => "#{request.ip}",
          :msg => "Invalid request for inbound lab. Unathorized user"
      }

      audit_log(AUDIT_TYPE_TRANS, AUDIT_TYPE_TRANS, auditoptions)

      api_svc_halt HTTP_BAD_REQUEST, '{"error":"Invalid request sent"}'

    end

    urllabinbound = ''
    urllabinbound << API_SVC_URL
    urllabinbound << 'labs/inboundrequest'

    LOG.debug("url for lab inbound request: " + urllabinbound)

    resp = generate_http_request(urllabinbound, "", request_body.to_json, "POST", settings.labs_user, settings.labs_pass)

    LOG.debug(resp.body)
    response_code = map_response(resp.code)

    status HTTP_OK

  end

  #  lab outbound - pass through to transmit JSON from Rails to Mirth
  #
  # POST /v1/lab/outbound
  #
  # server action: Return 200 if success, no content
  # server response:
  # --> if authenticated: 200
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  post '/v1/lab/outbound' do

    # Validate the input parameters
    request_body = get_request_JSON

    urllaboutbound = ''
    urllaboutbound << MIRTH_SVC_URL

    LOG.debug("url for lab outbound request: " + urllaboutbound)

    resp = generate_http_request(urllaboutbound, "", request_body.to_json, "POST")

    LOG.debug(resp.body)

    response_code = map_response(resp.code)

    status HTTP_OK

  end

end