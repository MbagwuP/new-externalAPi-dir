module ExternalAPI
  module Settings

    config_files = { 
      aws_sqs_queues:       'aws_sqs',
      swagger_environments: 'swagger_environments'
    }

    config_files.each do |k, v|
      file = File.join(APP_ROOT, "config", "#{v}.yml")
      self.const_set "#{k.upcase}", YAML.load(ERB.new(File.read(file)).result)[ENV['RACK_ENV'] || ::ApiService.settings.environment.to_s]
    end
    
  end
end
