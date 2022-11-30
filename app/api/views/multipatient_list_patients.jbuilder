
  json.array! @responses do |response|
    json.resource_count response[:count_summary] unless response[:count_summary].nil?
    json.patientEntries response[:resources].entries do |patient|
      json.partial! :patient_details,
                    patient: OpenStruct.new(patient["patient"]),
                    include_provenance_target: @include_provenance_target
    end
  end

