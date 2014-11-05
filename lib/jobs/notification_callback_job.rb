class NotificationCallbackJob
  include Resque::Plugins::Status

  @queue = :notification_callback_queue

  def perform
    begin
      uri = URI.parse(options['notification_callback']['notification_callback_url'])
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if options['notification_callback']['notification_callback_url'].include? "https"
      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] =  'application/json'
      request["HTTP-ACCEPT"] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
      request.body = options['notification_callback']['json_request'].to_json
      response = http.request(request)
      Rails.logger.debug ("....... NOTIFICATION_CALLBACK_RESPONSE code #{response.code}.. message.. #{response.message}") if !response.nil? and response.code != 200
      "passed"
    rescue Exception => e
      Rails.logger.fatal "Exception has occurred: #{e.to_s}"
      Rails.logger.fatal "#{e.backtrace.join("\n ")}"
    end
  end
end
