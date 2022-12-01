
  json.array! @responses do |response|
    json.resource_count response[:count_summary] unless response[:count_summary].nil?
    json.diagnosticReportEntries Array.wrap(response[:resources]) do |diagnostic_report|
      json.partial! :diagnostic_report, diagnostic_report: diagnostic_report, encounter: response[:encounter], provider: response[:provider], include_provenance_target:@include_provenance_target
    end
  end

