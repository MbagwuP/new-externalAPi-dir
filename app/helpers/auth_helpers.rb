class ApiService < Sinatra::Base

  def sign_internal_request(url:, method:, headers: {})
    request = RestClient::Request.new(:url => url, :method => method, :headers => headers)
    CCAuth::InternalService::Request.sign!(request)
  end

  # Convenience method for parsing the authorization token header
  def get_auth_token
    if env && env['HTTP_AUTHORIZATION']
      env['HTTP_AUTHORIZATION'].split(" ").last
    end
  end

  # Convenience method for parsing the authorization token header
  def get_modified_since_tag
    if env && env['HTTP_IF_MODIFIED_SINCE']
      env['HTTP_IF_MODIFIED_SINCE']
    end
  end

  def get_oauth_token
    if request.env['HTTP_AUTHORIZATION']
      CGI.unescape request.env["HTTP_AUTHORIZATION"].gsub('Bearer','').gsub(' ','')
    end
  end

  def escaped_oauth_token
    CGI::escape oauth_token
  end

  def authenticate_mirth_request(id, key)
    # key determination
    current_date = DateTime.now()

    mirth_key = ''
    mirth_key << MIRTH_PRIVATE_KEY
    mirth_key << current_date.strftime('%Y%m%d')
    mirth_key << id

    h = Digest::SHA2.new << mirth_key
    if key != h.to_s

      audit_options = {
          :ip => "#{request.ip}",
          :msg => 'Invalid request for inbound lab. Unauthorized user'
      }

      audit_log(AUDIT_TYPE_TRANS, AUDIT_TYPE_TRANS, audit_options)

      api_svc_halt HTTP_BAD_REQUEST, '{"error":"Invalid request sent"}'
    end

  end

  def oauth_request?
    token = request.env['HTTP_AUTHORIZATION']
    token && !token.include?('Basic') && token.length < 40
  end

  def oauth_token
    return @oauth_token if defined?(@oauth_token) # caching
    if request.env['HTTP_AUTHORIZATION']
      @oauth_token = CGI.unescape request.env["HTTP_AUTHORIZATION"].gsub('Bearer','').gsub(' ','')
    else
      api_svc_halt HTTP_NOT_AUTHORIZED, '{"error": "Access token is required"}'
    end
    @oauth_token
  end


end