class ApiService < Sinatra::Base
  ENTITY_ADDRESS_FIELDS = ['mailing_location', 'bill_to_location', 'pay_to_location'].freeze

  # /v2/practices
  post /\/v2\/practices$/ do
    begin
      request_body = get_request_JSON

      ENTITY_ADDRESS_FIELDS.each do |f|
        if (request_body['business_entity'][f])
          request_body['business_entity'][f]['state'] =
              WebserviceResources::Converter.code_to_cc_id(WebserviceResources::State, request_body['business_entity'][f]['state'])
        end
      end

      # replace state codes with ids
      addresses = request_body['business_entity'].slice(ENTITY_ADDRESS_FIELDS)
      addresses.each do |_, v|
        v['state'] = WebserviceResources::Converter.code_to_cc_id(WebserviceResources::State, state)
      end
      request_body['business_entity'].merge!(addresses)
      url = "#{ApiService::API_SVC_URL}businesses.json?token=#{escaped_oauth_token}"
      response = RestClient.post url, request_body.to_json, :content_type => :json, extapikey: ApiService::APP_API_KEY
    rescue ArgumentError => e
      errmsg = "Practice Creation Failed - #{e.message}"
      api_svc_halt HTTP_UNPROCESSABLE_ENTITY, errmsg
    rescue => e
      begin
        exception = error_handler_filter(e.response)
        errmsg = "Business Entity Creation Failed - #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        errmsg = "#{e.message}"
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    returnedBody = JSON.parse response.body
    response_hash = {:business_entity => returnedBody["business_entity"]}
    body(response_hash.to_json); status HTTP_CREATED
  end

end
