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
      if location['address'].present?
        temp_value['address'] = location['address']['address'].slice('city', 'county_name', 
                                       'latitude', 'line1', 'line2', 'line3', 'longitude',
                                        'zip_code') 
        temp_value['address']['state'] = WebserviceResources::Converter.cc_id_to_code(WebserviceResources::State, location['address']['address']['state_id'])
        temp_value['address']['zip_code'].insert(5, '-') if temp_value['address']['zip_code'].length == 9
      else
        temp_value['address'] = nil
      end
      return_value << temp_value
    end
    #LOG.debug(returned_provider_object)


    return body(return_value.to_json)

  end

end