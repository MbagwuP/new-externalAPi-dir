
json.resource_count @responses.count
json.ObservationEntries @responses do |response|
      if response[:observation].class == BloodPressureObservation
        json.partial! :blood_pressure_observation,
                      observation: response[:blood_pressure_observation],
                      observation_type: response[:observation_type],
                      include_provenance_target: @include_provenance_target
      elsif response[:observation].class == PulseOximetryObservation
        json.partial! :pulse_oximetry_observation,
                      observation: response[:pulse_oximetry_observation],
                      observation_type: response[:observation_type],
                      include_provenance_target: @include_provenance_target
      else
        if response[:observation].class == SocialHistorySection
        response[:observation].entries.each do |entry|
          json.partial! :observation_smoking_status, 
            smoking_status: entry,
            social_history_code: response[:observation].code, 
            patient: OpenStruct.new(response[:patient]), business_entity: OpenStruct.new(response[:business_entity]),
            provider: OpenStruct.new(response[:provider]), contact: OpenStruct.new(response[:contact]), 
            include_provenance_target: false
        end
         
        elsif response[:observation]['lab_request_test'].present?
             json.partial! :lab_result, lab_result:  OpenStruct.new(response[:observation]["lab_request_test"]), 
             provider:  OpenStruct.new(response[:provider]), 
             patient:  OpenStruct.new(response[:patient]),
             business_entity:  OpenStruct.new(response[:business_entity]), 
             code:  response[:code], observation_type:  response[:observation_type],
             include_provenance_target: false

        else
          json.partial! :observation,
                      observation: OpenStruct.new(response[:observation]),
                      observation_type: response[:observation_type],
                      include_provenance_target: @include_provenance_target
        end
      end
    end



