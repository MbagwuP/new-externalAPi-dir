#
# File:       charge_service.rb
#
#
# Version:    1.0


class ApiService < Sinatra::Base


  # {
  #     "charges": {
  #         "charge": {
  #             "provider_id": 2,
  #             "insurance_profile_id": 1,
  #             "attending_provider_id": 2,
  #             "supervising_provider_id": 2,
  #             "referring_physician_id" : 2,
  #             "clinical_case_id" : 1234,
  #             "authorization_id" : "1222AAS"
  #             "units": "each",
  #             "diagnosis1_code": "010.16",
  #             "diagnosis1_pointer": 1,
  #             "procedure_code": "51798",
  #             "location_id": 2,
  #             "start_time": "2013-05-08" (date_of_service)
  #         },
  #         "debit": {
  #             "amount": 355.75,
  #             "patient_id": 36910,
  #             "effective_date": "2013-05-08"
  #         }
  #     }
  # }
  # server response:
  # --> if appointment created: 201, with charge id returned
  # --> if not authorized: 401
  # --> if patient not found: 404
  # --> if bad request: 400
  post '/v1/charge/create?' do

    # Validate the input parameters
    request_body = get_request_JSON

    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    business_entity = get_business_entity(pass_in_token)

    ## add business entity to debit controller
    request_body['charges']['debit']['business_entity_id'] = business_entity

    ## validate provider id
    providerid = request_body['charges']['charge']['provider_id']

    ## validate the provider
    providerids = get_providers_by_business_entity(business_entity, pass_in_token)

    ## validate the request based on token
    check_for_valid_provider(providerids, providerid)

    #http://localservices.carecloud.local:3000/charges/create.json?token=
    urlcharge = ''
    urlcharge << API_SVC_URL
    urlcharge << 'charges/create.json?token='
    urlcharge << CGI::escape(pass_in_token)

    LOG.debug("url for charge create: " + urlcharge)
    LOG.debug(request_body.to_json)

    begin
      response = RestClient.post(urlcharge, request_body)
    rescue => e 
      begin
        errmsg = "Appointment Look Up Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end


    parsed = JSON.parse(response.body)

    body(parsed.to_json)

    status HTTP_OK

  end

end