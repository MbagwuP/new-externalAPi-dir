require 'sinatra'

module CircuLab
  # CircuLab Module contains the logic to immediately return mock LabCorb lab results in our 
  # non-Production environments. We only return lab results for the labs defined in the 
  # lab_test_results/orders directory. It's designed to return unique lab results every time.
  # 
  # Only requests that contain one or more matching labs will be processsed. All others will be ignored
  # 

  class Clinical < CircuLab::LabRequest
    # Clinical class just contains core methods to process the incoming request and send
    # the mocked response to Clincal API

    def initialize(request_body)
      super(request_body)
    end

    def is_approved_provider?
      # We will only allow mock results for one provider for now
      is_business_entity   = @request["circulab_business_entity_id"] == ENV['CONFIG_CIRCULAB_BUSINESS_ENTITY_ID']
      is_approved_provider = @request["circulab_provider_id"] == ENV['CONFIG_CIRCULAB_PROVIDER_ID']
      is_provider_npi      = @request["circulab_provider_npi"] == ENV['CONFIG_CIRCULAB_PROVIDER_NPI']
      is_business_entity && is_approved_provider && is_provider_npi
    end

    def process_lab_request
      # Calls the build process to mock a response back from Mirth with a collection of lab order results
      # This will either return an object with all the relevant key => values expected from a Mirth lab result
      # or nil.  

      return nil unless meets_circulab_response_criteria?
      begin
        build_lab_request_response
      rescue => e
        ApiService::LOG.debug { "Failed to build CircuLab response: #{e}" }
        return nil
      end
    end

    def send_circulab_test_results
      # This method will get the processed CircuLab payload and post it to Clinical API.
      # We check which environment first and then check if we have a proper lab result.
      #
      # If this is running in production, we exit immediately.
      #

      return if is_production?

      payload = process_lab_request
      return if payload.nil?

      ApiService::LOG.debug { "CircuLab Detected" }
      begin
        ApiService::LOG.debug { "CircuLab: \nEndpoint: #{clinical_observation_message_url}\n Request Body: #{payload.to_json}" }
        resp = RestClient.post(clinical_observation_message_url, payload.to_json, :content_type => :json)
      rescue => e
        ApiService::LOG.debug { "CircuLab: Request to Clinical API Failed:\n#{e}: #{e.response}" }
      else
        if (200..299).member?(resp.code)
          ApiService::LOG.debug { "CircuLab: Request to Clinical API Succesful" }
        else
          ApiService::LOG.debug { "CircuLab: Request to Clinical API Failed (Non 200 Range Response)\n#{resp.code}: #{resp.body}" }
        end
      end
    end
  end
end