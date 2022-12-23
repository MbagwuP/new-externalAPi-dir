class ApiService < Sinatra::Base

  # /v2/locations
  # /v2/appointment/locations (legacy)
  get /\/v2\/(appointment\/locations|locations)/ do
    #LOG.debug(business_entity)

    #http://localservices.carecloud.local:3000/public/businesses/1/locations.json?token=
    
    #returns all locations that can be viewed in patient portal ("public locations") and not all all
    all_flag = true_param?(params[:all_public]) 
    urllocation = webservices_uri "public/businesses/#{current_business_entity}/locations.json", token: escaped_oauth_token, all: all_flag
    response = rescue_service_call 'Location Look Up Failed' do
      RestClient.get(urllocation, :api_key => APP_API_KEY)
    end

    @locations = JSON.parse(response.body)
    @locations["locations"].each do |location| 
      if location['address'].present? && location['address']['zip_code'].length == 9 
        location['address']['zip_code'].insert(5, '-')
      end
    end
    
    body jbuilder :list_locations
    status HTTP_OK
  end

  get '/v2/location/:id' do

    location_id = params[:id]
    business_entity_id = current_business_entity
    base_path = "public/businesses/#{business_entity_id}/locations/#{location_id}/details.json"

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: {},
      rescue_string: 'Location '
    )

    @location = resp['location']
    @business_entity = resp['business_entity'] ? resp['business_entity']['business_entity'] : nil

    status HTTP_OK
    jbuilder :show_location
  end
end
