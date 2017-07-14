class ApiService < Sinatra::Base

  # /v2/visit_reasons
  # /v2/nature_of_visits (legacy)
  get /\/v2\/(nature_of_visits|visit_reasons)/ do
    nature_of_visit_url = webservices_uri "nature_of_visits/list_by_business_entity/#{current_business_entity}.json", nature_of_visit_params
    data = get_nature_of_visits(nature_of_visit_url)
    body(data.to_json)
    status HTTP_OK
  end

  get '/v2/appointment_resources/:resource_id/visit_reasons' do
    nature_of_visit_url = webservices_uri "nature_of_visits/list_by_business_entity/#{current_business_entity}.json", nature_of_visit_params.merge(filter_resource_id: params[:resource_id])                          
    data = get_nature_of_visits(nature_of_visit_url)
    body(data.to_json)
    status HTTP_OK
  end

  def get_nature_of_visits(url)
    response = rescue_service_call 'Visit Reason' do
      RestClient.get(url, :api_key => APP_API_KEY)
    end
    data = []
    parsed = JSON.parse(response.body)
    parsed.each do |x|
      filter_nov = {}
      filter_nov['id'] = x['nature_of_visit']['id']
      filter_nov['name'] = x['nature_of_visit']['name']
      filter_nov['description'] = x['nature_of_visit']['description']
      data.push filter_nov if x['nature_of_visit']['status'] == Status::ACTIVE
    end
    data
  end

  def nature_of_visit_params
    options = {token: escaped_oauth_token}
    options[:for_requests] = true_param?(params[:request_types_only])
    options
  end

end
