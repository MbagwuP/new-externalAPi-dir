json.insurance_profile do
  json.id @resp['insurance_profile']['id']
  json.is_default @resp['insurance_profile']['is_default']
  json.name @resp['insurance_profile']['name']
end
