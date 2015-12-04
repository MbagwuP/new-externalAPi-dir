class ApiService < Sinatra::Base

  get '/v2/patients/:patient_id/transactions' do
    forwarded_params = {start_date: params[:start_date], end_date: params[:end_date], page: params[:page], use_pagination: 'true'}
    if forwarded_params[:start_date].blank? && forwarded_params[:end_date].blank?
      forwarded_params[:end_date] = Date.today.to_s
      forwarded_params[:start_date] = Date.parse(30.days.ago.to_s).to_s # default to the past month's worth of transactions
    elsif !forwarded_params[:start_date].blank? && forwarded_params[:end_date].blank?
      forwarded_params[:end_date] = (Date.parse(forwarded_params[:start_date]) + 30.days).to_s # default to 30 days from the start date
    end

    patient_id = params[:patient_id]
    urltransactions = webservices_uri "patient_id/#{patient_id}/transactions.json", {token: escaped_oauth_token, business_entity_id: current_business_entity}.merge(forwarded_params)

    @resp = rescue_service_call 'Patient Transactions Look Up' do
      RestClient.get(urltransactions, :api_key => APP_API_KEY)
    end

    @resp = JSON.parse(@resp)
    status HTTP_OK
    jbuilder :list_transactions
  end

end
