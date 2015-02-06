class ApiService < Sinatra::Base

  get /\/v2\/(nature_of_visits|visit_reasons)/ do
    # /v2/visit_reasons
    # /v2/nature_of_visits (legacy)

    nature_of_visit_url = ''
    nature_of_visit_url << API_SVC_URL
    nature_of_visit_url << 'nature_of_visits/list_by_business_entity/'
    nature_of_visit_url << current_business_entity
    nature_of_visit_url << '.json?token='
    nature_of_visit_url << escaped_oauth_token

    begin
      response = RestClient.get(nature_of_visit_url, :api_key => APP_API_KEY)
    rescue => e
      begin
        errmsg = "Nature Of Visit Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
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
