json.ObservationEntries @observation_entries do |observation|
  json.partial! :observation, observation: OpenStruct.new(observation)
end