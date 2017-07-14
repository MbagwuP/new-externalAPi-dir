class ApiService < Sinatra::Base

  def set_preferred_confirmation_method(filtered)
    if filtered['confirmation_method'] && filtered['confirmation_method']['communication_method']
      # build new confirmation_method hash, and replace the old one
      confirmation_method_id = filtered['confirmation_method']['communication_method']['id']
      confirmation_method = communication_methods.invert[confirmation_method_id]
      filtered['preferred_confirmation_method'] = confirmation_method
    else
      filtered['preferred_confirmation_method'] = nil
    end
    filtered.delete('confirmation_method')
  end

  def get_appointment_internal_id (id, business_entity_id, pass_in_token)

    pass_in_token = pass_in_token
    appointmentid = id
    business_entity = business_entity_id
    #http://devservices.carecloud.local/appointments/1/abcd93832/listbyexternalid.json?token=
    urlappt = "#{API_SVC_URL}appointments/#{business_entity}/#{appointmentid}/listbyexternalid.json?token=#{CGI::escape(pass_in_token)}"

    begin
      response = RestClient.get(urlappt)
    rescue => e
      begin
        errmsg = "Appointment Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body).first
    return parsed["appointment"]["id"]
  end
  
  def transform_communication_params(request_body)
    communication_method_slug = request_body.delete('communication_method')
    request_body['communication_method_id'] = communication_methods[communication_method_slug]
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Missing or invalid communication method."}' if request_body['communication_method_id'].nil?
    if request_body['communication_outcome']
      communication_outcome_slug = request_body.delete('communication_outcome')
      request_body['communication_outcome_id'] = communication_outcomes[communication_outcome_slug]
      api_svc_halt HTTP_BAD_REQUEST, '{"error":"Missing or invalid communication outcome."}' if request_body['communication_outcome_id'].nil? 
    else
      # communication_outcome 6 is "confirmed" for /confirm
      request_body['communication_outcome_id'] = 6
    end
    request_body.rename_key('communication_method_description', 'method_description') if request_body['communication_method_description'].present?
    request_body
  end
  
  def appointment_guid_check(id)
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Appointment ID must be a valid GUID."}' unless id.is_guid?
  end
  
end