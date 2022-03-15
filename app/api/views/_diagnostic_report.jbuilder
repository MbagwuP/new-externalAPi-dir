json.status "final"
json.category_code "LAB"
json.category_code_system "http://hl7.org/fhir/DiagnosticReport-category"
json.category_code_display "Laboratory"
json.category_code_text "Laboratory"
json.test_date "2015-02-03T05:00:00+05:00"

json.lab_results @diagnostic_report.entries do |lab_result|
  json.lab_test_code lab_result.code.code
  json.lab_test_code_system lab_result.code.codeSystem
  json.lab_test_code_display
  json.lab_test_code_text lab_result.code.displayName
  json.result_status lab_result.status
  json.test_date lab_result.start_date
  json.result_value do
    json.value lab_result.measure_value
    json.unit lab_result.measure_unit
  end
end

