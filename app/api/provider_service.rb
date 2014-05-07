#
# File:       provider_service.rb
#
#
# Version:    1.0


class ApiService < Sinatra::Base


  #  get provider by API
  #
  #  GET /v1/provider/npi/<npinumber>
  #
  # Params definition
  # :npinumber - the npi number of the provider being looked for
  #
  # server action: Return provider id for the passed in NPI (if found)
  # server response:
  # --> if data found: 200, with CareCloud provider id in response body
  # --> if not authorized: 401
  # --> if provider not found: 404
  # --> if exception: 500
  get '/v1/provider/npi/:npinumber?' do

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    ##  get providers by business entity - check to make sure they are legit in pass in
    business_entity = get_business_entity(pass_in_token)

    returned_provider_id = nil

    npi_pass_in = params[:npinumber]

    provider_list = get_providers_by_business_entity(business_entity, pass_in_token)


    #LOG.debug(provider_list)

    begin

      provider_list['providers'].each { |x|
        if x['npi'].to_s == npi_pass_in.to_s
          returned_provider_id = x['id']
          break
        end
      }

    rescue
      api_svc_halt HTTP_BAD_REQUEST, '{"error":"NPI could not be matched"}'
    end

    unless returned_provider_id.nil?
      body(returned_provider_id.to_json)
      status HTTP_OK
    else
      api_svc_halt HTTP_BAD_REQUEST, '{"error":"NPI could not be matched"}'
    end

  end


  #  get provider information
  #
  # GET /v1/provider/list?authentication=<authenticationToken>
  #
  # Params definition
  # :none  - will be based on authentication
  #
  # server action: Return provider information for authenticated user
  # server response:
  # --> if data found: 200, with provider data payload
  # --> if not authorized: 401
  # --> if not found: 404
  # --> if exception: 500
  get '/v1/provider/list?' do


    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    business_entity = get_business_entity(pass_in_token)
    #LOG.debug(business_entity)

    ## save the result of this to the cache
    cache_key = "business-entity-" + business_entity + "-providers-" + CGI::unescape(pass_in_token)

    #LOG.debug("cache key: " + cache_key)

    #http://localservices.carecloud.local:3000/public/businesses/1/providers.json?token=
    urlprovider = ''
    urlprovider << API_SVC_URL
    urlprovider << 'public/businesses/'
    urlprovider << business_entity
    urlprovider << '/providers.json?token='
    urlprovider << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urlprovider)
    rescue => e
      begin
        errmsg = "Provider Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    body(response.body)

    status HTTP_OK

  end


end