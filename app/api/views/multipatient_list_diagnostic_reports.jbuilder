json.resource_count @responses.count
json.diagnosticReportEntries @responses do |diagnostic_lab|
  json.partial! :diagnostic_report, diagnostic_report: diagnostic_lab[:diagnostic_header],
   diagnostic_lab: diagnostic_lab, 
   encounter: diagnostic_lab[:encounter], 
   provider: diagnostic_lab[:provider], 
   patient: diagnostic_lab[:patient], 
   business_entity: diagnostic_lab[:business_entity], 
   include_provenance_target:@include_provenance_target
end


