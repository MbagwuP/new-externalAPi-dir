json.diagnostic_report_entries Array.wrap(@diagnostic_report) do |diagnostic_report|
  json.partial! :diagnostic_report, diagnostic_report: diagnostic_report
end

json.patient do
  json.partial! :patient, patient: OpenStruct.new(@patient)
end

json.business_entity do
  json.partial! :business_entity, business_entity: OpenStruct.new(@business_entity)
end
