json.diagnosticReportEntriesList do
  json.array! @responses do |response|
    json.resource_count response[:count_summary] unless response[:count_summary].nil?
    json.diagnostic_report_entries Array.wrap(response[:resources]) do |diagnostic_report|
      json.partial! :diagnostic_report, diagnostic_report: diagnostic_report
    end

    json.patient do
      json.partial! :patient, patient: OpenStruct.new(response[:patient])
    end

    json.business_entity do
      json.partial! :business_entity, business_entity: OpenStruct.new(response[:business_entity])
    end
  end
end
