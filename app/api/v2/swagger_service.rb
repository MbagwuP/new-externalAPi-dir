class ApiService < Sinatra::Base

  get '/v2/api-docs/swagger.json' do
    sw = SwaggerSchema.new(ExternalAPI::Settings::SWAGGER_ENVIRONMENTS['environment_url'], 'api-docs', :amazon_import)
    status HTTP_OK
    sw.to_json
  end

  get '/v2/api-docs' do
    content_type :html
    erb File.read('api-docs/swagger.erb'), layout: File.read('api-docs/layout.erb')
  end

  get '/v2/api-docs/help' do
    content_type :html
    erb File.read('api-docs/help.erb'), layout: File.read('api-docs/layout.erb')
  end

  get '/v2/api-docs/releases' do
    content_type :html
    @md_release_notes = Dir['api-docs/release_notes/*.md'].sort.reverse.map { |md|
      Markdown.new(File.read(md)).to_html
    }.join('<br/><hr/><br/>')
    erb File.read('api-docs/releases.erb'), layout: File.read('api-docs/layout.erb')
  end

  get '/docs' do
    redirect "https://#{request.host}/v2/api-docs"
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
