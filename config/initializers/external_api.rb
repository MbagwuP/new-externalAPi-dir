APP_ROOT = File.expand_path('../..', File.dirname(__FILE__)) unless defined?(APP_ROOT)

module ExternalAPI
  module Settings

    config_files = { 
      aws_sqs_queues:       'aws_sqs',
      swagger_environments: 'swagger_environments'
    }

    config_files.each do |k, v|
      file = File.join(APP_ROOT, "config", "#{v}.yml")
      self.const_set "#{k.upcase}", File.open(file){|f| YAML.load(f)}[ENV['RACK_ENV'] || ::ApiService.settings.environment.to_s]
    end
    
  end
end
