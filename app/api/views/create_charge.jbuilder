json.array! @charges do |charge|
json.id charge['id']
json.encounter_id charge['encounter_id']
end