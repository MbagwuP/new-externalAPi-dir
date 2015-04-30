class ApiService < Sinatra::Base

  get '/integration_landing' do
    content_type :html
    erb File.read('app/views/integration_landing/choice.erb')
    # erb File.read('api-docs/help.erb'), layout: File.read('api-docs/layout.erb')
  end

  get '/integration_landing/login' do
    content_type :html
    erb File.read('app/views/integration_landing/login.erb')
  end

  post '/integration_landing/login' do
    params.delete('error')
    content_type :html

    urllogin = webservices_uri 'login.json', login: params[:user_name], password: params[:password]
    begin
      login_response = RestClient.get(urllogin)
    rescue Exception => e
      redirect_error_url = "/integration_landing/login?error=#{CGI.escape 'Login failed, please try again.'}"
      redirect_error_url << '&zocdoc=true' if params[:zocdoc] == 'true'
      redirect redirect_error_url
    end

    login_response = JSON.parse(login_response)
    token = login_response['authtoken']
    if token.nil?
      raise 'Invalid Login'
    end
    openam_id = login_response['user']['login']
    user_id = login_response['user']['id']
    contact_id = login_response['user']['contact_id']

    # reach out to auth and get user GUID for token from session
    urlsession = "#{CCAuth.endpoint}/sessions/#{token}"
    session = RestClient.get(urlsession)
    user_guid = JSON.parse(session)['user']['guid']

    # reach out to auth and get entities
    urlentities = "#{CCAuth.endpoint}/accounts/#{user_guid}"
    entities = RestClient.get(urlentities, authorization: token)
    @entities = JSON.parse(entities)

    urllogout = webservices_uri 'logout.json', token: token
    logout_response = rescue_service_call 'Logout' do
      RestClient.get(urllogout)
    end

    puts logout_response

    erb File.read('app/views/integration_landing/be_select.erb')

  end

  post '/integration_landing/finish' do
    params.delete('error')
    content_type :html

    if params[:zocdoc]
      @copy = 'We sent your info to ZocDoc Service'
      # Webservices Show Business Entity
      # Webservices Show Person by Contact ID
      # send email to ZocDoc Service
    else
      @copy = 'We sent your info to ZocDoc Sales'
      # API call create referral in Salesforce
    end

    erb File.read('app/views/integration_landing/confirm.erb')
  end

end
