class ApiService < Sinatra::Base

  def debit_transaction_types
    return @debit_transaction_types if defined?(@debit_transaction_types) # caching
    cache_key = "debit-transaction-types"

    begin
      @debit_transaction_types =  XAPI::Cache.fetch(cache_key, 54000) do
        debit_transaction_types_from_webservices
      end
    rescue Dalli::DalliError
      LOG.warn("cannot reach cache store")
      @debit_transaction_types = debit_transaction_types_from_webservices
    rescue CCAuth::Error::ResponseError => e
      api_svc_halt e.code, e.message
    end
    @debit_transaction_types
  end

  def debit_transaction_types_from_webservices
    urlco = webservices_uri "debit_transactions/types/list_all.json"

    resp = rescue_service_call 'Debit Transaction Type Look Up' do
      request = RestClient::Request.new(url: urlco, method: :get, headers: {api_key: APP_API_KEY})
      CCAuth::InternalService::Request.sign!(request).execute
    end

    resp = JSON.parse resp
    output = {}
    resp.each do |co|
      key = co['debit_transaction_type']['name'].underscore.gsub(' ', '_')
      val = co['debit_transaction_type']['id']
      output[key] = val
    end
    output
  end

  def credit_transaction_types
    return @credit_transaction_types if defined?(@credit_transaction_types) # caching
    cache_key = "credit-transaction-types"

    begin
      @credit_transaction_types = XAPI::Cache.fetch(cache_key, 54000) do
        credit_transaction_types_from_webservices
      end
    rescue Dalli::DalliError
      LOG.warn("cannot reach cache store")
      @credit_transaction_types = credit_transaction_types_from_webservices
    rescue CCAuth::Error::ResponseError => e
      api_svc_halt e.code, e.message
    end
    @credit_transaction_types
  end

  def credit_transaction_types_from_webservices
    urlco = webservices_uri "credit_transactions/types/list_all.json"

    resp = rescue_service_call 'Credit Transaction Type Look Up' do
      request = RestClient::Request.new(url: urlco, method: :get, headers: {api_key: APP_API_KEY})
      CCAuth::InternalService::Request.sign!(request).execute
    end

    resp = JSON.parse resp
    output = {}
    resp.each do |co|
      key = co['credit_transaction_type']['name'].underscore.gsub(' ', '_')
      val = co['credit_transaction_type']['id']
      output[key] = val
    end
    output
  end

  def transaction_statuses
    return @transaction_statuses if defined?(@transaction_statuses) # caching
    cache_key = "transaction-statuses"

    begin
      @transaction_statuses = XAPI::Cache.fetch(cache_key, 54000) do
        transaction_statuses_from_webservices
      end
    rescue Dalli::DalliError
      LOG.warn("cannot reach cache store")
      @transaction_statuses = transaction_statuses_from_webservices
    rescue CCAuth::Error::ResponseError => e
      api_svc_halt e.code, e.message
    end
    @transaction_statuses
  end

  def transaction_statuses_from_webservices
    urlco = webservices_uri "transactions/statuses/list_all.json"

    resp = rescue_service_call 'Transaction Status Look Up' do
      request = RestClient::Request.new(url: urlco, method: :get, headers: {api_key: APP_API_KEY})
      CCAuth::InternalService::Request.sign!(request).execute
    end

    resp = JSON.parse resp
    output = {}
    resp.each do |co|
      key = co['transaction_status']['name'].underscore.gsub(' ', '_')
      val = co['transaction_status']['id']
      output[key] = val
    end
    output
  end

end


