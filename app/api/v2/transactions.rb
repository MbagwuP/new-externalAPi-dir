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


        
