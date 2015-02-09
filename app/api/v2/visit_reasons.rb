class ApiService < Sinatra::Base

  # /v2/visit_reasons
  # /v2/nature_of_visits (legacy)
  get /\/v2\/(nature_of_visits|visit_reasons)/ do
    nature_of_visit_url = webservices_uri "nature_of_visits/list_by_business_entity/#{current_business_entity}.json",
                                           token: escaped_oauth_token

    response = rescue_service_call 'Visit Reason' do
      RestClient.get(nature_of_visit_url, :api_key => APP_API_KEY)
    end

    data = []
    parsed = JSON.parse(response.body)
    parsed.each do |x|
        filter_nov = {}
        filter_nov['id'] = x['nature_of_visit']['id']
        filter_nov['name'] = x['nature_of_visit']['name']
        filter_nov['description'] = x['nature_of_visit']['description']
        data.push filter_nov
      end
    body(data.to_json)
    status HTTP_OK
  end

end
