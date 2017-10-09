json.insurance_profiles @profiles do |profile|
  json.id profile['id']
  json.name profile['name']
  json.self_pay profile['is_self_pay']
  json.default  profile['is_default']
  json.insurance_policies profile['policies'] do |policy|
    json.policy_priority policy['priority']
    json.member_number policy['member_number']
    json.policy_number policy['policy_number']    
    json.effective_from policy['effective_from']
    json.effective_to policy['effective_to']
    json.co_payment policy['co_payment']
    json.type profile['name']
    json.group_name policy['group_name']
    json.insured do
      json.first_name policy['insured']['first_name']
      json.last_name policy['insured']['last_name']
      json.middle_initial policy['insured']['middle_initial']
      json.gender WebserviceResources::Converter.cc_id_to_code(WebserviceResources::Gender, policy['insured']['gender_id'])
      json.relation_to_patient policy['primary_insured_relationship_type']
      json.addresses policy['insured']['addresses'] do |address|
        json.partial! 'address', address: address['address']
      end
      json.phones policy['insured']['phones'] do |phone|
        json.partial! 'phone', phone: phone['phone']
      end
    end
    json.payer do
      json.id policy['payer']['id']
      json.name policy['payer']['name']
      json.phones policy['payer']['phones'] do |phone|
        json.partial! 'phone', phone: phone['phone']
      end
      json.address do
        json.partial! 'address', address: policy['payer']['address']
      end
    end
  end
end