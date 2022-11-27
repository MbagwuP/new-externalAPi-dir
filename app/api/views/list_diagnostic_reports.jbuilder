json.diagnostic_report_entries Array.wrap(@diagnostic_report) do |diagnostic_report|
  json.partial! :diagnostic_report, diagnostic_report: diagnostic_report, encounter: @encounter, provider: @provider, include_provenance_target:@include_provenance_target
end


