
json.ObservationEntries @responses do |response|
    json.resource_count response[:count_summary] unless response[:count_summary].nil?
    # json.ObservationEntries response[:resources] do |observation|
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
        json.partial! :observation,
                      observation: OpenStruct.new(response[:observation]),
                      observation_type: response[:observation_type],
                      include_provenance_target: @include_provenance_target
      end
    end
  # end

