class ApiService < Sinatra::Base

  get '/v2/api-docs/swagger.json' do
    base = YAML.load_file 'api-docs/base.yml'
    base['paths'] = YAML.load_file 'api-docs/paths.yml'
    base['definitions'] = YAML.load_file 'api-docs/definitions.yml'
    body base.to_json
    status HTTP_OK
  end

  get '/v2/api-docs' do
    content_type :html
    erb File.read 'api-docs/swagger.erb'
  end

  post '/v2/api-docs/demotoken' do 
    # Some thoughts on how this can work:
    # - create token authorization request with Demo Business Entity and API Docs Application, and all OAuth roles (needs user token to authorize)
    # - call oauth2/access_token with the authorization code to get the first (and only) token for this grant (needs basic auth with API key/secret to authorize)

    404 # disable this endpoint for now
    # response = RestClient::Request.execute(:method => :post, :url => '/oauth2/access_token',
    #               :user => 'mnQ2yOcOAGVRVL8VujUcC3TpufkueozK', :password => 'ly8JZ0RKyx9jQyLi',
    #               :payload => {grant_type: 'refresh_token', refresh_token: 'rEZKRVRrqM6S95yc_xNjhGS_UFvf0HH7'})
    # body response
    # status HTTP_OK
  end

end
