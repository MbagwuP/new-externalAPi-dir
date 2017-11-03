class ApiService < Sinatra::Base
  
  SELF = "1"
  
  def insurance_param_validator(policy)
    required_params = ["effective_date","member_number","insured_person_relationship", "payer", "insurance_policy_type"]
    required_params.each do |param|
    api_svc_halt HTTP_BAD_REQUEST, "#{param} is required." unless policy.has_key?(param)
    end
  end
  
  def create_insured_person_relationship_hash(policy)
    begin
      if policy['primary_insured_person_relationship_type_id'] != SELF
        raise NoMethodError if policy['insured'].empty? 
        gender_id = if policy['insured']['gender_code']
                      policy['insured'].delete('gender_code')
                    else
                      policy['insured'].delete('gender')
                    end
        policy['insured']['gender_id'] = WebserviceResources::Converter.code_to_cc_id(WebserviceResources::Gender, gender_id)
        if policy['insured']['phones']
          policy['insured']['phones'].each do |y|
            phone_type = if y['phone_type_code']
                            y.delete('phone_type_code')
                          else
                            y.delete('phone_type')
                          end
            y['phone_type_id'] = WebserviceResources::Converter.code_to_cc_id(WebserviceResources::PhoneType, phone_type)
          end
        end
        if policy['insured']['addresses']
          policy['insured']['addresses'].each do |y|
            convert_state_code_to_id(y)
            convert_country_code_to_id(y)
          end
        end
      else
        policy.delete('insured')
      end
    rescue NoMethodError
      api_svc_halt HTTP_BAD_REQUEST, "Missing or Invalid insured person"
    end
  end
  
  def convert_payer_address(payer)
    convert_state_code_to_id(payer['address'])
    convert_country_code_to_id(payer['address'])
  end
  
  def convert_state_code_to_id(policy)
    state = if policy['state_code']
              policy.delete('state_code')
            else
              policy.delete('state')
            end
    policy['state_id'] = WebserviceResources::Converter.code_to_cc_id(WebserviceResources::State, state)
  end
    
  def convert_country_code_to_id(policy)
    country = if policy['country_code']
              policy.delete('country_code')
            else
              policy.delete('country')
            end
    policy['country_id'] = WebserviceResources::Converter.code_to_cc_id(WebserviceResources::Country, country)
  end
  
end