
json.identifier provider['id']
json.npi provider['npi']
json.name provider['name']
json.email provider['email']
if (provider['primary_phone'].present? && provider['primary_phone']['phone'].present?)
  json.phone_number provider['primary_phone']['phone']['phone_number']
else
  json.phone_number nil
end
if (provider['primary_specialty'].present? && provider['primary_specialty']['specialty'].present?)
  json.specialty do
    json.name provider['primary_specialty']['specialty']['name']
    json.taxonomy provider['primary_specialty']['specialty']['taxonomy_code']
  end
else 
  json.specialty nil
end
json.last_name provider['last_name']
json.first_name provider['first_name']