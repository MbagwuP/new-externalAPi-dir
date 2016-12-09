require 'sinatra'
module CircuLab
  module Settings
    # These are just some general settings we use throughout the CircuLab modules
    extend self

    def clinical_observation_message_url
      # The Clinical API url with Mirth Key
      "#{ENV['CONFIG_CLINICAL_API_URL']}/v1/clinical/observation-messages/?key=#{ENV['CONFIG_CIRCULAB_MIRTH_KEY']}&id=#{ENV['CONFIG_CIRCULAB_MIRTH_ID']}"
    end

    def environment
      # Returns the current environment
      ENV['RACK_ENV'].downcase rescue "development" || Sinatra::Application.settings.environment.to_s.downcase
    end

    def is_production?
      # CircuLab results should NOT be triggered in production
      environment == 'production'
    end

    def format_file_name(file_name)
      # Removes unnecessary characters from the file name
      file_name.downcase.gsub!(/-|,| |\//,'_') || file_name.downcase
    end

    def orders_file_path(name)
      # Path to our lab order templates
      "app/modules/circulab/lab_test_results/orders/#{name}"
    end
  end
end