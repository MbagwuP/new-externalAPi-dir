require 'sinatra'

module CircuLab

  class Clinical

    def initialize(request_body)
      @request      = request_body
      @lab_tests    = @request["lab_tests"]
      @environment  = ENV['RACK_ENV'].downcase || Sinatra::Application.settings.environment.to_s.downcase
    end

    def clinical_observation_message_url
      "#{ENV['CONFIG_CLINICAL_API_URL']}/v1/clinical/observation-messages/?key=#{ENV['CONFIG_CIRCULAB_MIRTH_KEY']}&id=#{ENV['CONFIG_CIRCULAB_MIRTH_ID']}"
    end

    def is_production?
      # CircuLab results should NOT be triggered in production
      @environment == 'production'
    end

    def is_approved_provider?
      # We will only allow mock results for one provider for now
      is_business_entity   = @request["circulab_business_entity_id"] == ENV['CONFIG_CIRCULAB_BUSINESS_ENTITY_ID']
      is_approved_provider = @request["circulab_provider_id"] == ENV['CONFIG_CIRCULAB_PROVIDER_ID']
      is_provider_npi      = @request["circulab_provider_npi"] == ENV['CONFIG_CIRCULAB_PROVIDER_NPI']
      is_business_entity && is_approved_provider && is_provider_npi
    end

    def has_approved_amount_of_labs?
      # For now we want to limit the amount of labs tests to 1 lab per order.
      # We will revisit this limitation in the future.
      @lab_tests.size == 1
    end

    def has_approved_lab?
      # Check if lab order has an approved lab which we will send back back to Clinical API
      # with a mock result.
      get_lab_test_result.any?
    end

    def lab_file_name
      # The Circulab test results are stored in json files in the lab_results directory
      # The naming pattern for these mock labs are as follows: 
      # universal-service-identifier_universal-service-description.json
      # Example: 123456_some_test.json
      lab_identifier  = @lab_tests.first["universal_service_identifier"]
      test_name       = @lab_tests.first["universal_service_description"].downcase
      "#{lab_identifier}_#{test_name}.json"
    end

    def get_lab_test_result
      # Globs the lab_test_results directory and filters files that match the 
      # lab_file_name of the lab tests. Should return an array with a single file name
      # or an empty collection
      Dir.glob("app/modules/circulab/lab_test_results/*.json").select { |file| file.include?(lab_file_name)}
    end

    def lab_interpolation
      lab_test_result = get_lab_test_result.first.to_s
      begin
        lab_file        = File.open(lab_test_result, "r")
        lab_test        = @lab_tests.first
        now             = DateTime.now.strftime("%Y%m%d%H%M")
        patient_dob_raw = DateTime.strptime(@request["guarantor_dob"], '%m/%d/%Y').strftime("%Y%m%d")
        lab_file.read % {lab_tracer_number: @request["lab_tracer_number"],
                          sending_application_identifier: @request["sending_application_identifier"],
                          sending_facility_identifier: @request["sending_facility_identifier"],
                          receiving_application_identifier: @request["receiving_application_identifier"],
                          receiving_facility_identifier: @request["receiving_facility_identifier"],
                          message_created_at: now,
                          patient_external_identifier: @request["patient_external_identifier"],
                          patient_last_name: @request["patient_last_name"],
                          patient_first_name: @request["patient_first_name"],
                          patient_dob_raw: patient_dob_raw,
                          patient_gender: @request["patient_gender"],
                          patient_account_number: @request["patient_account_number"],
                          placer_order_identifier: lab_test["placer_order_identifier"],
                          filler_order_identifier: lab_test["placer_order_identifier"],
                          ordering_provider_last_name: lab_test["ordering_provider_last_name"],
                          ordering_provider_first_name: lab_test["ordering_provider_first_name"],
                          ordering_provider_npi: lab_test["ordering_provider_npi"],
                          observation_text: lab_test["universal_service_description"],
                          observation_code_type: lab_test["universal_service_coding_system"],
                          observation_at: "#{now}T093000-0400",
                          observation_date: now,
                          universal_service_identifier: lab_test["universal_service_identifier"],
                          universal_service_description: lab_test["universal_service_description"],
                          specimen_received_at: "#{now}T093000-0400",
                          specimen_received_date: now,
                          order_effective_date: "#{now}T093000-0400",
                          resulted_or_updated_at: "#{now}T093000-0400",
                          status_change_or_result_date: now}
      rescue => e
        ApiService::LOG.debug { "Lab interoplation failed: #{e}" }
        return nil
      end
    end

    def send_circulab_test_results
      return if is_production?
      return unless is_approved_provider? && has_approved_amount_of_labs? && has_approved_lab?
       ApiService::LOG.debug { "CircuLab Detected" }
      payload = lab_interpolation
      return if payload.nil?

      begin
        resp = RestClient.post(clinical_observation_message_url, payload, :content_type => :json)
      rescue => e
        ApiService::LOG.debug { "Sending CircuLab to Clinical API Failed: #{e}: #{e.response}" }
      else
        if (200..299).member?(resp.code)
          ApiService::LOG.debug { "Sending CircuLab to Clinical API Succesful" }
        else
          ApiService::LOG.debug { "Sending CircuLab to Clinical API Failed: #{resp.code}: #{resp.body}" }
        end
      end
    end
  end
end