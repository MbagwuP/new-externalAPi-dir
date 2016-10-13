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


end