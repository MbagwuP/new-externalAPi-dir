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

    urllogin = "#{CCAuth.endpoint}/users/authenticate"
    begin
      login_response = RestClient.post(urllogin, {user_name: params[:user_name], password: params[:password]})
    rescue Exception => e
      redirect_error_url = "/integration_landing/login?error=#{CGI.escape 'Login failed, please try again.'}"
      redirect_error_url << '&zocdoc=true' if params[:zocdoc] == 'true'
      redirect redirect_error_url
    end

    login_response = JSON.parse(login_response)
    require 'pry'; binding.pry
    token = login_response['access_token']
    if token.nil?
      raise 'Invalid Login'
    end

    # reach out to auth and get user GUID for token from session
    urlsession = "#{CCAuth.endpoint}/sessions/#{token}"
    session = RestClient.get(urlsession)
    user_guid = JSON.parse(session)['user']['guid']

    # reach out to auth and get entities
    urlentities = "#{CCAuth.endpoint}/accounts/#{user_guid}"
    entities = RestClient.get(urlentities, authorization: token)
    @entities = JSON.parse(entities)

    urllogout = "#{CCAuth.endpoint}/logout"
    logout_response = rescue_service_call 'Logout' do
      RestClient.post(urllogout, authorization: token)
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
