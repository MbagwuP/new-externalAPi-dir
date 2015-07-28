class ApiService < Sinatra::Base

  # /v2/locations
  # /v2/appointment/locations (legacy)
  get /\/v2\/(appointment\/locations|locations)/ do
    #LOG.debug(business_entity)

    #http://localservices.carecloud.local:3000/public/businesses/1/locations.json?token=

    urllocation = webservices_uri "public/businesses/#{current_business_entity}/locations.json", token: escaped_oauth_token
    response = rescue_service_call 'Location Look Up Failed' do
      RestClient.get(urllocation, :api_key => APP_API_KEY)
    end

    parsed = JSON.parse(response.body)
    parsed["locations"].each do |location| 
      if location['address'].present? && location['address']['zip_code'].length == 9 
        location['address']['zip_code'].insert(5, '-')
      end
    end
    body(parsed.to_json)
    status HTTP_OK
  end

end
