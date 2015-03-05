class ApiService < Sinatra::Base

  get /\/v2\/(provider\/list|providers)/ do
    # /v2/providers
    # /v2/provider/list (legacy)

    ## save the result of this to the cache
    cache_key = "business-entity-" + current_business_entity + "-providers-" + oauth_token
    # LOG.debug("cache key: " + cache_key)

    #http://localservices.carecloud.local:3000/public/businesses/1/providers.json?token=
    urlprovider = webservices_uri "public/businesses/#{current_business_entity}/providers.json", token: escaped_oauth_token

    response = rescue_service_call 'Provider' do
      RestClient.get(urlprovider, :api_key => APP_API_KEY)
    end

    body(response.body)
    status HTTP_OK
  end

end
