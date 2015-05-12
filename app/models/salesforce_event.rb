class SalesforceEvent

  attr_reader :sqs, :event_type, :payload

  def initialize(event_type, payload)
    @sqs        = CareCloud::Queue::Client.new
    @event_type = event_type
    @payload    = payload
  end

  def push_to_sqs
    # begin
      sqs.send_message(queue_url: ExternalAPI::Settings::AWS_SQS_QUEUES['salesforce_queue_url'],
                       message_body: message_body.to_json)
    # rescue => e
      # ApiService::LOG.error(e.message)
    # end
  end

  def message_body
    { event_type: @event_type, payload: @payload }
  end
end
