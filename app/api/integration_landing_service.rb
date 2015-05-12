class ApiService < Sinatra::Base

  get '/integration_landing' do
    content_type :html
    erb File.read('app/views/integration_landing/choice.erb')
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
      login_response = RestClient.post(urllogin, {user_name: params[:user_email], password: params[:password], include_scope: true})
    rescue Exception => e
      redirect_error_url = "/integration_landing/login?error=#{CGI.escape 'Login failed, please try again.'}"
      redirect_error_url << '&zocdoc=true' if params[:zocdoc] == 'true'
      redirect redirect_error_url
    end

    login_response = JSON.parse(login_response)
    token = login_response['access_token']
    if token.nil?
      raise 'Invalid Login'
    end

    user_guid = login_response['user']['guid']
    user_full_name = login_response['user']['full_name']
    user_email = login_response['user']['email']

    # reach out to auth and get entities
    urlentities = "#{CCAuth.endpoint}/accounts/#{user_guid}"
    entities = RestClient.get(urlentities, authorization: token)
    @entities = JSON.parse(entities)
    @token = token

    erb File.read('app/views/integration_landing/be_select.erb')

  end

  post '/integration_landing/finish' do
    params.delete('error')
    content_type :html

    session = CCAuth::Session.find_by_token(params[:token])

    if params[:zocdoc]
      @copy = 'We sent your info to ZocDoc Service'
      event = SalesforceEvent.new('IntegrationSignup.CarecloudZocdocJoint.Completed',
        { practice_id: params[:practice_id], user_email: params[:user_email], first_name: session.user.first_name, last_name: session.user.last_name, full_name: session.user.full_name })
      event.push_to_sqs
    else
      @copy = 'We sent your info to ZocDoc Sales'
      event = SalesforceEvent.new('IntegrationSignup.ReferralToZocdoc.Completed',
        { practice_id: params[:practice_id], user_email: params[:user_email], first_name: session.user.first_name, last_name: session.user.last_name, full_name: session.user.full_name })
      event.push_to_sqs
    end

    erb File.read('app/views/integration_landing/confirm.erb')
  end

end
