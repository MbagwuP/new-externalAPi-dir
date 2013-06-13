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
        pass_in_token = URI::decode(params[:authentication])

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
        urlcharge << URI::encode(pass_in_token)

        LOG.debug("url for charge create: " + urlcharge)
        LOG.debug(request_body.to_json)

        #resp = generate_http_request(urlcharge, "", request_body.to_json, "POST")

        LOG.debug(resp.body)
        response_code = map_response(resp.code)

        if response_code == HTTP_CREATED

                parsed = JSON.parse(resp.body)
                LOG.debug(parsed)

                returned_value = parsed["patient"]["external_id"]
                the_response_hash = { :patient => returned_value }
                body(the_response_hash.to_json)
        else
            body(resp.body)
        end

        status response_code

    end
	  
end