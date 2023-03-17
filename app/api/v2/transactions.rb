class ApiService < Sinatra::Base

  get '/v2/patients/:patient_id/transactions' do
    date_params = get_date_params(params)
    forwarded_params = {start_date: date_params[0], end_date: date_params[1], page: params[:page], use_pagination: 'true', only_posted: 'true'}

    patient_id = params[:patient_id]
    urltransactions = webservices_uri "patients/#{patient_id}/transactions.json", {token: escaped_oauth_token, business_entity_id: current_business_entity}.merge(forwarded_params)

    @resp = rescue_service_call 'Patient Transactions Look Up' do
      RestClient.get(urltransactions, :api_key => APP_API_KEY)
    end

    @resp = JSON.parse(@resp)
    status HTTP_OK
    jbuilder :list_transactions
  end

  get '/v2/patients/:patient_id/charges' do
    date_params = get_date_params(params)
    forwarded_params = {start_date: date_params[0], end_date: date_params[1], page: params[:page], use_pagination: 'true',
                        debit_transaction_type_ids: [debit_transaction_types['charge'], debit_transaction_types['simple_charge']]}

    patient_id = params[:patient_id]
    urltransactions = webservices_uri "patients/#{patient_id}/transactions.json", {token: escaped_oauth_token, business_entity_id: current_business_entity}.merge(forwarded_params)

    @resp = rescue_service_call 'Patient Charges Look Up' do
      RestClient.get(urltransactions, :api_key => APP_API_KEY)
    end

    @resp = JSON.parse(@resp)
    status HTTP_OK
    jbuilder :list_transactions
  end

  post '/v2/patients/:patient_id/charge' do
    begin
      @charges =  ChargeResource.create(get_request_JSON,params[:patient_id],escaped_oauth_token,current_business_entity)
    rescue => e
      begin
        exception = e.message
        api_svc_halt e.http_code, exception
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, exception
      end
    end
    status HTTP_CREATED
    jbuilder :create_charge
  end

  post '/v2/patients/:patient_id/simple_charge' do
    begin
      @simple_charge = SimpleChargeResource.create(get_request_JSON,params[:patient_id],escaped_oauth_token)
    rescue => e
      begin
        exception = e.message
        api_svc_halt e.http_code, exception
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, exception
      end
    end
    status HTTP_CREATED
    jbuilder :create_simple_charge
  end

  get '/v2/simple_charge_types' do
    begin
      url = webservices_uri "simple_charges_types/business_entity/#{current_business_entity}/get.json", {token: escaped_oauth_token}
      response = rescue_service_call 'List Simple Charge Types',true do
        RestClient.get(url, api_key: APP_API_KEY)
      end
      @resp = JSON.parse(response.body)
    rescue => e
      begin
        exception = error_handler_filter(e.response)
        errmsg = "Simple Charge Type Look Up Failed- #{exception}"
        api_svc_halt e.http_code, errmsg
      rescue
        errmsg = "Simple Charge Type Look Up Failed- #{e.message}"
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    status HTTP_OK
    jbuilder :list_simple_charge_types
  end

  get '/v2/claims/get-claim-data' do
    date_params = get_date_params(params)
    forwarded_params = {start_date: date_params[0], end_date: date_params[1], page: params[:page], use_pagination: 'true',
                          business_entity_id: params[:business_entity_id], handled: params[:handled], claim_ids: params[:claim_ids]
                       }
                        
    urlclaim = webservices_uri "claims/get-claim-data.json", {token: escaped_oauth_token}.merge(forwarded_params)

    @resp = rescue_service_call 'Claims Look Up' do
      RestClient.get(urlclaim, :api_key => APP_API_KEY)
    end

    @resp = JSON.parse(@resp)
    status HTTP_OK
    body(@resp.to_json)
  end

  post '/v2/claims/save-claim-data' do
      request_body = get_request_JSON
      urlclaimsave = webservices_uri "claims/save-claim-data.json", {token: escaped_oauth_token}
      @resp = rescue_service_call 'Save Claim' do
        RestClient.post(urlclaimsave, request_body.to_json, :content_type => :json)
      end

      @resp = JSON.parse(@resp)
      status HTTP_OK
      body(@resp.to_json)
  end

  private

    def get_date_params(params)
      if params[:start_date].present? && params[:end_date].present?
        [params[:start_date], params[:end_date]]
      elsif params[:start_date].blank? && params[:end_date].blank?
        # by default only return 30 days of transactions
        [Date.parse(30.days.ago.to_s).to_s, Date.today.to_s]
      elsif params[:start_date].present? && params[:end_date].blank?
        # start date but no end date supplied, default to 30 days from start date
        [params[:start_date], (Date.parse(params[:start_date]) + 30.days).to_s]
      else
        api_svc_halt HTTP_BAD_REQUEST, 'Both start_date and end_date parameters are required for date filtering'
      end
    end

end
