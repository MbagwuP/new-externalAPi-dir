patient = OpenStruct.new(@patient)
lab_result = OpenStruct.new(@lab_result)
business_entity = OpenStruct.new(@business_entity)
provider = OpenStruct.new(@provider)
test_date="2015-02-03T05:00:00+05:00"
category_code="LAB"

json.diagnosticReport do

  json.account_number patient.external_id

  json.mrn patient.chart_number
  json.patient_name lab_result['lab_request_test']["patient_first_name"] + " " + lab_result['lab_request_test']["patient_last_name"]
  json.identifier lab_result['lab_request_test']["id"]
  json.external_id patient.external_id
  json.text lab_result['lab_request_test']["lab_request_test_description"]
  json.status "final"
  json.text_status 'generated'
  json.category_code category_code
  json.category_code_system "http://hl7.org/fhir/DiagnosticReport-category"
  json.category_code_display "Laboratory"
  json.category_code_text "Laboratory"
  json.code @diagnostic_report.code.code
  json.code_text lab_result['lab_request_test']["lab_request_test_description"]
  json.code_display lab_result['lab_request_test']["lab_request_test_description"]
  json.lab_test_code_system lab_result['lab_request_test']["lab_request_test_code"]
  json.effective_period_start lab_result['lab_request_test']["ordered_at"]
  json.effective_period_end lab_result['lab_request_test']["updated_at"]
  json.test_date test_date
  json.labResult do

    json.account_number patient.external_id

    json.mrn patient.chart_number
    json.patient_name lab_result['lab_request_test']["patient_first_name"] + " " + lab_result['lab_request_test']["patient_last_name"]
    json.identifier lab_result['lab_request_test']["id"]
    json.text  lab_result['lab_request_test']["lab_request_test_description"]
    json.text_status 'generated'
    json.result_status 'final'
    json.lab_test_code @diagnostic_report.code.code
    json.lab_test_code_system "http://hl7.org/fhir/DiagnosticReport-category"
    json.lab_test_code_display @diagnostic_report.code.displayName
    json.code_text lab_result['lab_request_test']["lab_request_test_description"]
    json.code_display lab_result['lab_request_test']["lab_request_test_description"]
    json.lab_test_code_system lab_result['lab_request_test']["lab_request_test_code"]
    json.effective_period_start lab_result['lab_request_test']["ordered_at"]
    json.effective_period_end lab_result['lab_request_test']["updated_at"]
    json.result_value do
      json.value nil
      json.value_unit nil
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



end