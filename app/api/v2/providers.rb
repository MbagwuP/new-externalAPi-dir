class ApiService < Sinatra::Base

  get /\/v2\/(provider\/list|providers)/ do
    # /v2/providers
    # /v2/provider/list (legacy)

    ## save the result of this to the cache
    cache_key = "business-entity-" + current_business_entity + "-providers-" + oauth_token
    # LOG.debug("cache key: " + cache_key)

    #http://localservices.carecloud.local:3000/public/businesses/1/providers.json?token=
    urlprovider = webservices_uri "public/businesses/#{current_business_entity}/providers.json?", token: escaped_oauth_token, associations: "primary_specialty,primary_phone"


    response = rescue_service_call 'Provider' do
      RestClient.get(urlprovider, :api_key => APP_API_KEY)
    end

    @providers = JSON.parse(response)['providers'].map do |provider|
      status = provider.delete('status')
      provider if status == Status::ACTIVE
    end
    @providers.compact!
    status HTTP_OK
    jbuilder :show_providers
  end
end