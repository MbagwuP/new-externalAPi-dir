json.diagnosticReportEntries @lab_requests do |diagnostic_lab|
  json.partial! :diagnostic_report, diagnostic_report: @diagnostic_report, diagnostic_lab: diagnostic_lab, encounter: @encounter, provider: @provider, patient: @patient, business_entity: @business_entity, include_provenance_target:@include_provenance_target
end


