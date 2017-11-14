json.insurance_profile do
  json.id @resp['insurance_profile']['id']
  json.name @resp['insurance_profile']['name']
  json.insurance_policies @resp['insurance_profile']['insurance_policies'] do |policy|
    json.id policy['id']
    json.priority policy['priority']
    json.payer_pending_approval policy['is_pending']
    json.updated_at policy['updated_at']
  end
end

