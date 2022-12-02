patient = OpenStruct.new(@patient)
lab_result = OpenStruct.new(lab_result)
business_entity = OpenStruct.new(@business_entity)
provider = OpenStruct.new(@provider)
test_date="2015-02-03T05:00:00+05:00"
category_code="LAB"
json.diagnosticReport do

  if ((@include_code_target == @diagnostic_report.code.code || @include_code_target == nil) && (@include_category_target == category_code || @include_category_target == nil) && (@include_date_target == test_date || @include_date_target == nil))

    json.account_number patient.external_id

    json.mrn patient.chart_number
    json.patient_name @lab_results[0]['lab_request_test']["patient_first_name"] + " " + @lab_results[0]['lab_request_test']["patient_last_name"]
    json.identifier @lab_results[0]['lab_request_test']["id"]
    json.external_id patient.external_id
    json.text @lab_results[0]['lab_request_test']["lab_request_test_description"]
    json.status "final"
    json.text_status 'generated'
    json.category_code category_code
    json.category_code_system "http://hl7.org/fhir/DiagnosticReport-category"
    json.category_code_display "Laboratory"
    json.category_code_text "Laboratory"
    json.code @diagnostic_report.code.code
    json.code_text @lab_results[0]['lab_request_test']["lab_request_test_description"]
    json.code_display @lab_results[0]['lab_request_test']["lab_request_test_description"]
    json.lab_test_code_system @lab_results[0]['lab_request_test']["lab_request_test_code"]
    json.effective_period_start @lab_results[0]['lab_request_test']["ordered_at"]
    json.effective_period_end @lab_results[0]['lab_request_test']["updated_at"]
    json.test_date test_date
    json.labResult @lab_results do |lab_result_value|
      labs_result=lab_result_value['lab_request_test']
      json.account_number patient.external_id

      json.mrn patient.chart_number
      json.patient_name labs_result["patient_first_name"] + " " + labs_result["patient_last_name"]
      json.identifier labs_result["id"]
      json.text  labs_result["lab_request_test_description"]
      json.text_status 'generated'
      json.result_status 'final'
      json.lab_test_code @diagnostic_report.code.code
      json.lab_test_code_system "http://hl7.org/fhir/DiagnosticReport-category"
      json.lab_test_code_display @diagnostic_report.code.displayName
      json.code_text labs_result["lab_request_test_description"]
      json.code_display labs_result["lab_request_test_description"]
      json.lab_test_code_system labs_result["lab_request_test_code"]
      json.effective_period_start labs_result["ordered_at"]
      json.effective_period_end labs_result["updated_at"]
      json.result_value do
        json.value lab_result.measure_value
        json.value_unit lab_result.measure_unit
        json.value_code nil
        json.value_unit nil
      end
      json.reference_range_low do
        json.value lab_result.reference_lower_bound
        json.value_code nil
        json.value_code_system nil
        json.value_unit nil
      end
      json.reference_range_high do
        json.value lab_result.reference_upper_bound
        json.value_code nil
        json.value_code_system nil
        json.value_unit nil
      end
      json.business_entity do
        json.partial! :business_entity, business_entity: business_entity
      end
    end

    json.subject do
      json.reference "Patient/"+patient.external_id
      json.display @lab_results[0]['lab_request_test']["patient_first_name"] + " " + @lab_results[0]['lab_request_test']["patient_last_name"]
    end

    json.encounter do
      json.reference "Encounter/#{encounter['id']}"
    end

    json.performer do
      json.reference "Practitioner/"+provider['id'].to_s
    end
    if include_provenance_target
      json.partial! :provenance, patient: patient, record: lab_result, provider: provider, business_entity: business_entity, obj: 'DiagnosticReport'
    end
    json.patient do
      json.partial! :patient, patient: OpenStruct.new(@patient)
    end

    json.business_entity do
      json.partial! :business_entity, business_entity: OpenStruct.new(@business_entity)
    end
  end

end