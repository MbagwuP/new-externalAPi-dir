#
# File:       location_service.rb
#
#
# Version:    1.0

class ApiService < Sinatra::Base

  #input: Business_entity from token
  #output: id,name field of location.
  get '/v1/get/locations?' do

    pass_in_token = CGI::unescape(params[:authentication])

    business_entity = get_business_entity(pass_in_token)

    urllocation = ''
    urllocation << API_SVC_URL
    urllocation << 'businesses/'
    urllocation << business_entity
    urllocation << '/location.json?token='
    urllocation << CGI::escape(pass_in_token)

    begin
      resp = RestClient.get(urllocation)
    rescue => e
      begin
        errmsg = "Get Location List Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    return_value = []
    returned_locations_by_business_entity = JSON.parse(resp.body)
    returned_locations_by_business_entity.each do |location|
      temp_value = {}
      temp_value['id'] = location['id']
      temp_value['name'] = location['name']
      return_value << temp_value
    end
    #LOG.debug(returned_provider_object)


    return body(return_value.to_json)

  end

end