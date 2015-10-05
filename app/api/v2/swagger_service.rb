class ApiService < Sinatra::Base

  options "*" do
    # this is required for CORS in the Swagger docs at developer.carecloud.com
    # these headers are currently being generated by API Gateway, we just need to have the 200 here
    # response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
    # response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept, Authorization"
    200
  end

  get '/v2/api-docs/swagger.json' do
    base = YAML.load_file 'api-docs/base.yml'
    base['paths'] = YAML.load_file 'api-docs/paths.yml'
    base['definitions'] = YAML.load_file 'api-docs/definitions.yml'
    body base.to_json
    status HTTP_OK
  end

  get '/v2/api-docs' do
    if USE_AMAZON_API_GATEWAY
      docs_url = ExternalAPI::Settings::SWAGGER_ENVIRONMENTS['cors_url']
      response.headers["Location"] = docs_url
      return 301
    end

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
    if USE_AMAZON_API_GATEWAY
      docs_url = ExternalAPI::Settings::SWAGGER_ENVIRONMENTS['cors_url']
      response.headers["Location"] = docs_url
      return 301
    end

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
    # # test bamboo
  end

end
