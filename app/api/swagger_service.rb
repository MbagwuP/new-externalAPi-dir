class ApiService < Sinatra::Base

  get '/api-docs/swagger.json' do
    base = YAML.load_file 'api-docs/base.yml'
    base['paths'] = YAML.load_file 'api-docs/paths.yml'
    base['definitions'] = YAML.load_file 'api-docs/definitions.yml'
    body base.to_json
    status HTTP_OK
  end

  get '/api-docs' do
    content_type :html
    erb File.read 'public/api-docs/swagger.html'
  end

  post '/api-docs/demotoken' do 
=begin

- create token authorization request with Demo BE and API Docs App, and all OAuth roles (needs user token to authorize)
- call oauth2/access_token with the authorization code to get the first (and only) token for this grant (needs basic auth with API key/secret to authorize)

=end

    response = RestClient::Request.execute(:method => :post, :url => 'http://localhost:9292/oauth2/access_token',
                  :user => 'mnQ2yOcOAGVRVL8VujUcC3TpufkueozK', :password => 'ly8JZ0RKyx9jQyLi',
                  :payload => {grant_type: 'refresh_token', refresh_token: 'rEZKRVRrqM6S95yc_xNjhGS_UFvf0HH7'})
    body response
    status HTTP_OK
  end

end
