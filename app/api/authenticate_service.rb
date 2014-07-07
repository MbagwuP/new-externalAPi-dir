#
# File:       authenticate_service.rb
#
#
# Version:    1.0

class ApiService < Sinatra::Base


  #  authenticate
  #
  # POST /v1/service/authenticate
  #
  # Params definition
  # HTTP Basic AUTH
  #
  # server action: Return authentication token
  # server response:
  # --> if authenticated: 200, with token payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  post '/v1/service/authenticate' do

    begin

      auth ||= Rack::Auth::Basic::Request.new(request.env)
      # Debug code to help resolve login issues.  Do not deploy this code.
      # begin
      # LOG.debug ("Provided ok") if auth.provided?
      # LOG.debug ("Basic ok") if auth.basic?
      # LOG.debug ("Creds provided") if auth.credentials

      #LOG.debug ("Received creds: Username: #{auth.credentials.fetch(0)} Password: #{auth.credentials.fetch(1)}")
      # end

      #assign
      begin
        user_name = auth.credentials.fetch(0)
        password = auth.credentials.fetch(1)
      rescue
        api_svc_halt HTTP_BAD_REQUEST, '{"error":"Invalid Credentials"}'
      end

      #validation of request
      api_svc_halt HTTP_BAD_REQUEST, '{"error":"Username Not Found"}' if user_name.empty?
      api_svc_halt HTTP_BAD_REQUEST, '{"error":"Password Not Found"}' if password.empty?

      # put together URL (<<) listed as fastest means to concat
      urlauth = ''
      urlauth << API_SVC_URL
      urlauth << 'login.json?login='
      urlauth << user_name
      urlauth << '&password='
      urlauth << password

      #LOG.debug(urlauth)

      begin
        resp = RestClient.get(urlauth)
      rescue => e
        begin
          errmsg = "Authenticate Failed - #{e.message}"
          api_svc_halt e.http_code, errmsg
        rescue
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end


      parsed = JSON.parse(resp.body)
      #LOG.debug(parsed)

      ## store the business entity in the cache for the user
      ## TODO: Enhancement: Send in the default BusinessEntity here and store without the second call
      get_business_entity(parsed["authtoken"])

      ##TODO: this works, check in apps/model/login in main WS
      ##John wants the token to not have any encoded content - darren investigating
      #LOG.debug(parsed["authtoken_nonencoded"])
      the_token_hash = {:token => CGI::unescape(parsed["authtoken"])}
      body(the_token_hash.to_json)

      status HTTP_OK

    rescue => e
      handle_exception(e)
    end

  end

  #  authenticate
  #
  # POST /v1/service/authenticate
  #
  # Params definition
  # HTTP Basic AUTH
  #
  # server action: Return authentication token
  # server response:
  # --> if authenticated: 200, with token payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  post '/v2/service/authenticate' do

    begin

      auth ||= Rack::Auth::Basic::Request.new(request.env)
      # Debug code to help resolve login issues.  Do not deploy this code.
      # begin
      #LOG.debug ("Provided ok") if auth.provided?
      #LOG.debug ("Basic ok") if auth.basic?
      #LOG.debug ("Creds provided") if auth.credentials

      #LOG.debug ("Received creds: Username: #{auth.credentials.fetch(0)} Password: #{auth.credentials.fetch(1)}")
      # end

      #assign
      user_name = auth.credentials.fetch(0)
      password = auth.credentials.fetch(1)

      #validation of request
      api_svc_halt HTTP_BAD_REQUEST, '{"error":"Username Not Found"}' if user_name.empty?
      api_svc_halt HTTP_BAD_REQUEST, '{"error":"Password Not Found"}' if password.empty?

      # put together URL (<<) listed as fastest means to concat
      urlauth = ''
      urlauth << API_SVC_URL
      urlauth << 'login.json'

      #LOG.debug(urlauth)

      # make client call
      begin
        resource = RestClient::Resource.new( urlauth, { :user => user_name, :password => password})
        resp = resource.post("")
      rescue => e
        begin
          errmsg = "Authentication Failed - #{e.message}"
          api_svc_halt e.http_code, errmsg
        rescue
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end

      #resp = generate_http_request(urlauth, "", "", "POST", user_name, password)
      parsed = JSON.parse(resp.body)
      #LOG.debug(parsed)

      ## store the business entity in the cache for the user
      ## TODO: Enhancement: Send in the default BusinessEntity here and store without the second call
      get_business_entity(parsed["authtoken"])

      ##TODO: this works, check in apps/model/login in main WS
      ##John wants the token to not have any encoded content - darren investigating
      #LOG.debug(parsed["authtoken_nonencoded"])
      the_token_hash = {:token => CGI::unescape(parsed["authtoken"])}
      body(the_token_hash.to_json)


      status HTTP_OK

    rescue => e
      handle_exception(e)
    end

  end


  #  logout
  #
  # POST /v1/service/logout
  #
  # Params definition
  #   - authentication - token to logout
  #
  # server response:
  # --> if logged out: 200
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  post '/v1/service/logout?' do

    # Validate the input parameters
    token = params[:authentication]

    ## /logout.json?token=
    urllogout = ''
    urllogout << API_SVC_URL
    urllogout << 'logout.json?token='
    urllogout << CGI::escape(token)

    #LOG.debug("url for logout: " + urllogout)

    begin
      resp = RestClient.post(urllogout, "", :content_type => :json)
    rescue => e
      begin
        errmsg = "Appointment Creation Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    body(resp.body)

    status HTTP_OK

  end

  #CC Authentication/Authorization

  # OAUTH2 endpoints
  get '/oauth2/authorize' do
    content_type :html
    begin
      begin
        resp = CCAuth::OAuth2.new.oauth_dialog params
      rescue => e
        begin
          errmsg = e.message
          api_svc_halt e.code, errmsg
        rescue
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end

      body resp.body
      status HTTP_OK

    rescue => e
      handle_exception(e)
    end
  end

  post '/oauth2/authorize' do
    begin
      begin
        resp = CCAuth::OAuth2.new.oauth_authorize params
      rescue => e
        begin
          errmsg = e.message
          api_svc_halt e.code, errmsg
        rescue
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end

      error = "error=#{resp.headers['cc_oauth2_status_error']}"

      if [ 302, 303 ].include?(resp.status)
        redirect to base_url + request.fullpath + '&' + error unless resp.headers['cc_oauth2_status_error'].blank?
        redirect to resp.headers['location']
      end

    rescue => e
      handle_exception(e)
    end
  end

  post '/oauth2/access_token' do
    begin
      auth = Rack::Auth::Basic::Request.new(request.env)
      begin
        user_name, password = auth.credentials.fetch(0), auth.credentials.fetch(1)
      rescue
        api_svc_halt HTTP_BAD_REQUEST, '{"error":"Invalid Credentials"}'
      end

      begin
        resp = CCAuth::OAuth2.new.access_token user_name, password, params
      rescue => e
        begin
          errmsg = e.message
          api_svc_halt e.code, errmsg
        rescue
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end

      body resp.body
      status HTTP_OK

    rescue => e
      handle_exception(e)
    end
  end

  get '/oauth2/token_info' do
    begin
      begin
        resp = CCAuth::OAuth2.new.token_info(get_oauth_token || params[:access_token])
      rescue => e
        begin
          errmsg = e.message
          api_svc_halt e.code, errmsg
        rescue
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end

      body resp.body
      status HTTP_OK

    rescue => e
      handle_exception(e)
    end
  end

  #authenticate vi auth_service
  post '/v3/service/authenticate' do
    begin
      auth = Rack::Auth::Basic::Request.new(request.env)
      begin
        user_name, password = auth.credentials.fetch(0), auth.credentials.fetch(1)
      rescue
        api_svc_halt HTTP_BAD_REQUEST, '{"error":"Invalid Credentials"}'
      end

      api_svc_halt HTTP_BAD_REQUEST, '{"error":"Username Not Found"}' if user_name.empty?
      api_svc_halt HTTP_BAD_REQUEST, '{"error":"Password Not Found"}' if password.empty?

      begin
        resp = CCAuth::Session.create user_name, password
      rescue => e
        begin
          errmsg = e.message
          api_svc_halt e.code, errmsg
        rescue
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end

      parsed = resp.attributes
      get_business_entity parsed["access_token"]
      the_token_hash = { token: parsed["access_token"] }
      body the_token_hash.to_json
      status HTTP_OK

    rescue => e
      handle_exception(e)
    end
  end  

  # # Logout through auth_service 
  post '/v3/service/logout' do
    begin
      resp = CCAuth::Session.logout params[:authentication]
    rescue => e
      begin
        errmsg = e.message
        api_svc_halt e.status, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    body resp.body
    status HTTP_OK
  end

end