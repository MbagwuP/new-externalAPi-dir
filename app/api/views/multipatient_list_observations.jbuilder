json.ObservationEntriesList do
  json.array! @responses  do |response|
    json.resource_count response[:count_summary] unless response[:count_summary].nil?
    json.ObservationEntries response[:resources] do |observation|
      if observation.class == BloodPressureObservation
        json.partial! :blood_pressure_observation,
                      observation: response[:blood_pressure_observation],
                      observation_type: response[:observation_type],
                      include_provenance_target: @include_provenance_target
      elsif observation.class == PulseOximetryObservation
        json.partial! :pulse_oximetry_observation,
                      observation: response[:pulse_oximetry_observation],
                      observation_type: response[:observation_type],
                      include_provenance_target: @include_provenance_target
      else
        json.partial! :observation,
                      observation: OpenStruct.new(observation),
                      observation_type: response[:observation_type],
                      include_provenance_target: @include_provenance_target
      end
    end
  end
end
