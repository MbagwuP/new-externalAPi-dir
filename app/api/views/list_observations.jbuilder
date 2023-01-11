json.resource_count @count_summary unless @count_summary.nil?
json.ObservationEntries @observation_entries do |observation|
	if observation.class == BloodPressureObservation
		json.partial! :blood_pressure_observation, 
		observation: @blood_pressure_observation, 
		observation_type: @observation_type, 
		include_provenance_target: @include_provenance_target
	elsif observation.class == PulseOximetryObservation
  		json.partial! :pulse_oximetry_observation, 
		observation: @pulse_oximetry_observation, 
		observation_type: @observation_type, 
		include_provenance_target: @include_provenance_target
	else
  		json.partial! :observation, 
		observation: OpenStruct.new(observation), 
		observation_type: @observation_type, 
		include_provenance_target: @include_provenance_target
	end
end