
 json.resource_count @responses.count
 json.patient @responses do |response|
      json.partial! :patient_details,
                    patient: OpenStruct.new(response[:resources][0]["patient"]),
                    include_provenance_target: @include_provenance_target
    end


