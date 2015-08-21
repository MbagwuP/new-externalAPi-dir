namespace :swagger_schema do

  task :amazon_import => :environment do
    environment_url = ENV['NGROK'] == 'true' ? ExternalAPI::Settings::SWAGGER_ENVIRONMENTS['ngrok_url'] : ExternalAPI::Settings::SWAGGER_ENVIRONMENTS['environment_url']
    ENV['RACK_ENV'] = 'ngrok' if ENV['NGROK'] == 'true'
    sw = SwaggerSchema.new(environment_url, 'api-docs', :amazon_import)
    puts JSON.pretty_generate(sw.to_h)
  end

  task :public_docs => :environment do
    sw = SwaggerSchema.new(ExternalAPI::Settings::SWAGGER_ENVIRONMENTS['environment_url'], 'api-docs', :public_docs)
    puts JSON.pretty_generate(sw.to_h)
  end

end
