patient = OpenStruct.new(patient)
lab_result = OpenStruct.new(lab_result)
business_entity = OpenStruct.new(business_entity)
provider = OpenStruct.new(provider)
test_date="2015-02-03T05:00:00+05:00"
default_category_code="LAB"
json.diagnosticReport do
  json.account_number patient.external_id

  json.mrn patient.chart_number
  json.patient_name diagnostic_lab['lab_request_test']["patient_first_name"] + " " + diagnostic_lab['lab_request_test']["patient_last_name"]
  json.identifier diagnostic_lab['lab_request_test']["id"]
  json.external_id patient.external_id
  json.text diagnostic_lab['lab_request_test']["lab_request_test_description"]
  json.status "final"
  json.text_status 'generated'
  json.category_code diagnostic_lab['lab_request_test']["loinc"] || default_category_code
  json.category_code_system "http://terminology.hl7.org/CodeSystem/v2-0074"
  json.category_code_display "Laboratory"
  json.category_code_text "Laboratory"
  json.code diagnostic_report.code.code
  json.code_text diagnostic_lab['lab_request_test']["lab_request_test_description"]
  json.code_display diagnostic_lab['lab_request_test']["lab_request_test_description"]
  json.code_system "http://loinc.org/"
  json.lab_test_code_system diagnostic_lab['lab_request_test']["lab_request_test_code"]
  json.effective_period_start diagnostic_lab['lab_request_test']["ordered_at"]
  json.effective_date diagnostic_lab['lab_request_test']["ordered_at"]
  json.effective_period_end diagnostic_lab['lab_request_test']["updated_at"]
  json.test_date test_date
  json.labResult do
    json.array!([:once]) do
      labs_result=diagnostic_lab['lab_request_test']
      json.account_number patient.external_id

      json.mrn patient.chart_number
      json.patient_name labs_result["patient_first_name"] + " " + labs_result["patient_last_name"]
      json.identifier "#{labs_result["id"]}-#{ObservationType::LAB_REQUEST}"
      json.text  labs_result["lab_request_test_description"]
      json.text_status 'generated'
      json.result_status 'final'
      json.lab_test_code diagnostic_report.code.code
      json.lab_test_code_system "http://hl7.org/fhir/DiagnosticReport-category"
      json.lab_test_code_display diagnostic_report.code.displayName
      json.code_text labs_result["lab_request_test_description"]
      json.code_display labs_result["lab_request_test_description"]
      json.lab_test_code_system labs_result["lab_request_test_code"]
      json.effective_date labs_result["ordered_at"]
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
  end

  json.subject do
    json.reference "Patient/"+patient.external_id
    json.display diagnostic_lab['lab_request_test']["patient_first_name"] + " " + diagnostic_lab['lab_request_test']["patient_last_name"]
  end

  json.presented_form do
    json.array!([:once]) do
      json.content_type "image/tiff"
      json.data diagnostic_lab['lab_request_test']['data']
    end
  end

  json.encounter do
    json.reference "Encounter/#{encounter['id']}"
  end

  json.performer do
    json.array!([:once]) do
      json.reference "Practitioner/"+provider['id'].to_s
    end
  end

  json.patient do
    json.partial! :patient, patient: patient
  end

  json.business_entity do
    json.partial! :business_entity, business_entity: business_entity
  end

end

if include_provenance_target
  json.partial! :provenance, patient: patient, record: OpenStruct.new(diagnostic_lab['lab_request_test']), provider: provider, business_entity: business_entity, obj: 'DiagnosticReport'
end