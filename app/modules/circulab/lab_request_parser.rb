module CircuLab
  class LabRequestParser
    # This class will parse the incoming lab order request that is sent from WebServices
    # We store certain fields and values for future use in different parts of our response
    # body.
    # 
    # The fields and transformations we make in this class are expected in the json response
    # that will contain our lab order results.
    # 

    include CircuLab::Settings

    attr_accessor :request

    def initialize(request_body)
      @request            = request_body
      @parsed_lab_tests   = parsed_lab_tests
      @timestamp          = DateTime.now.strftime("%Y%m%d%H%M")
      @at_times           = @timestamp + "T093000-0400"
    end

    def patient_dob_raw
      DateTime.strptime(@request["guarantor_dob"], '%m/%d/%Y').strftime("%Y%m%d")
    end

    def parsed_lab_tracer
      {lab_tracer_number: @request["lab_tracer_number"]}
    end

    def parsed_lab_request
      {receiving_application_identifier: @request["sending_application_identifier"],
      receiving_facility_identifier: @request["sending_facility_identifier"],
      sending_application_identifier: @request["receiving_application_identifier"],
      sending_facility_identifier: @request["receiving_facility_identifier"],
      placer_account_number: @request["sending_facility_identifier"], 
      message_created_at: @timestamp,
      patient_external_identifier: @request["patient_external_identifier"],
      patient_last_name: @request["patient_last_name"],
      patient_first_name: @request["patient_first_name"],
      patient_dob_raw: patient_dob_raw,
      patient_dob: @request["patient_dob"],
      patient_gender: @request["patient_gender"]}
    end

    def lab_count
      @request["lab_tests"].size
    end

    def lab_test(lab)
      {placer_order_identifier: lab["placer_order_identifier"],
      filler_order_identifier: lab["placer_order_identifier"],
      ordering_provider_last_name: lab["ordering_provider_last_name"],
      ordering_provider_first_name: lab["ordering_provider_first_name"],
      ordering_provider_npi: lab["ordering_provider_npi"],
      observation_text: lab["universal_service_description"],
      observation_code_type: lab["universal_service_coding_system"],
      observation_at: @at_times,
      observation_date: @timestamp,
      universal_service_identifier: lab["universal_service_identifier"],
      universal_service_description: lab["universal_service_description"],
      specimen_received_at: @at_times,
      specimen_received_date: @timestamp,
      order_effective_date: @at_times,
      resulted_or_updated_at: @at_times,
      status_change_or_result_date: @timestamp}
    end

    def parsed_lab_tests
    # This returns a collection of lab maps with the parsed data from the request. 
    # The key of each map is the formatted lab name which we use later on for easier reference.

      @request["lab_tests"].map { |lab| 
        {format_lab_file_name(lab).to_sym => lab_test(lab)}
      }
    end

    def format_lab_file_name(lab_test)
      # The Circulab test results are stored in json files in the lab_results directory
      # The naming pattern for these mock labs are as follows: 
      # universal-service-identifier_universal-service-description.json
      # Example: 123456_some_test.json

      lab_identifier  = lab_test["universal_service_identifier"]
      test_name       = format_file_name(lab_test["universal_service_description"]) 
      "#{lab_identifier}_#{test_name}.json"
    end

    def lab_test_file_names
      # Returns a collection of lab file names that exist in the request body.
      @request["lab_tests"].map { |lab_test|
        format_lab_file_name(lab_test)
      } 
    end
  end
end