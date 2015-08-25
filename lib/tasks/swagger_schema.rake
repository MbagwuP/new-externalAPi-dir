namespace :swagger_schema do

  task :amazon_import => :environment do
    sw = SwaggerSchema.new(ExternalAPI::Settings::SWAGGER_ENVIRONMENTS['environment_url'], 'api-docs', :amazon_import)
    puts JSON.pretty_generate(sw.to_h)
  end

  task :public_docs => :environment do
    sw = SwaggerSchema.new(ExternalAPI::Settings::SWAGGER_ENVIRONMENTS['environment_url'], 'api-docs', :public_docs)
    puts JSON.pretty_generate(sw.to_h)
  end

end
