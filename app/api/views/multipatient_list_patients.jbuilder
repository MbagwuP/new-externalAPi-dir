
  json.patient @responses do |response|
    json.resource_count response[:count_summary] unless response[:count_summary].nil?
      json.partial! :patient_details,
                    patient: OpenStruct.new(response[:resources][0]["patient"]),
                    include_provenance_target: @include_provenance_target
    end


