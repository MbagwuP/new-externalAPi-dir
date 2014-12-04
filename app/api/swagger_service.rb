class ApiService < Sinatra::Base

  get '/api-docs/swagger.json' do
    # body YAML.load_file('public/swagger.yaml').to_json
    base = YAML.load_file 'api-docs/base.yml'
    base['paths'] = YAML.load_file 'api-docs/paths.yml'
    base['definitions'] = YAML.load_file 'api-docs/definitions.yml'
    body base.to_json
    status HTTP_OK
  end

  get '/api-docs' do
    # this doesn't work yet, just access it here for now:
    # http://localhost:9292/api-docs/swagger.html
    #
    # erb File.read 'public/api-docs/swagger.html'
  end

end
