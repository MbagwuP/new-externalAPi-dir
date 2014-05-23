#
# File:       inbound_mail_service
#
#
# Version:    1.0
#

# Use the following to test locally
# curl --form to=johnw --form subject=test --form from=bryan --form attachments=2 --form text="This is the body of the email" --form attachment1=@test.jpg --form attachment2=@test2.jpg --form envelope="{\"to\":[\"johnw\"],\"from\":[\"bryan\"]}"  localhost:1234/inbound_mail

class ApiService < Sinatra::Base
    
    post '/inbound_mail' do

        # hack to get Token
        urlauth  = API_SVC_URL + 'login.json?login=interface@interface.com&password=welcome'
        resp = RestClient.get(urlauth)
        parsed = JSON.parse(resp.body)
        token = CGI::unescape(parsed['authtoken'])
        LOG.debug "Auth token:#{token}"
        
        begin
        
            LOG.debug "To: #{params['to']} CC: #{params['cc']} From: #{params['from']} Subject: #{params['subject']}"
            LOG.debug "Envelope:#{params['envelope']}"
        
            # Sendgrid documentation states that the envelope[:to] JSON will be an array of recipients.
            # However, in practice it appears that Sendgrid is calling this service for every recipient
            # The To: CC: and From: fields are from the email header and should not be used to parse
            
            num_attachments = params['attachments'].to_i

            recipients = JSON.parse(params['envelope'])['to']
            recipients.each do |recipient|
            
                LOG.debug "Processing recipient:#{recipient}"
                # Find provider and BE based on recipients
                provider = find_provider_by_email(recipient)
                LOG.debug("provider:#{provider}")
                
                next if provider['providerID'].nil?
                
                # Loop through the attachments; upload to DMS and Create a Task in the providers Inbox
                i = 1
                while i <=  num_attachments
                    begin
                        temp_file = Tempfile.new('inbound')         # Do now so exception handler doesn't error
                    
                        attachment_name = "attachment#{i}"
                        document_binary = params[attachment_name][:tempfile]
                        document_name = params[attachment_name][:filename]
                        extname = File.extname(document_name)
                        
                        if extname != '.jpg' && extname != '.pdf'
                            LOG.error "Skipping attachment(#{i}): #{document_name}, attachments must be of type PDF or JPG"
                        else
                            LOG.debug "Processing attachment(#{i}): #{document_name}"

                            # Save file locally
                            document_binary.rewind
                            File.open(temp_file, "wb") do |file|
                                file.write(document_binary.read)
                            end

                            # Upload to DMS
                            response = dms_upload(temp_file, token)
                            docID = response['nodeid']
                            LOG.debug "DMS handler id: #{docID}"

                            # Create a task in the respective inbox
                            # Use "from" field to differeniate Inbound Fax vs other documents
                            if JSON.parse(params['envelope'])['from'][0] == 'faxserver@carecloud.com'
                                docType = 'Fax'
                            else
                                docType = 'Document'
                            end
                            taskID = add_to_provider_inbox(provider['providerID'], provider['business_entity'], docID, params['subject'], params['text'], token, docType)
                            LOG.debug "Task id: #{taskID}"
                        end

                    rescue Exception => e
                        LOG.error "Error processing attachment(#{i}): #{e.message}"

                        # Swallow all exceptions and move onto next attachment
                    end

                    # Little Housekeeping
                    File.delete(temp_file) if File.exists?(temp_file)

                    i += 1
                end

                if num_attachments == 0
                    # Create a task in the respective inbox
                    taskID = add_to_provider_inbox(provider['providerID'], provider['business_entity'], nil, params['subject'], params['text'], token, 'Tickler')
                    LOG.debug "Task id: #{taskID}"
                end
            end
        rescue Exception => e
            LOG.error "Inbound_mail Error: #{e.message}"
        end

        # Failure to return 200 will cause Sendgrid to retry until 200 is received.
        status HTTP_OK
    end

    ## Using the recipient email address find the provider ID
    def find_provider_by_email (recipient)

        response = {"providerID" => "123456", "business_Entity" => "1234"}
        return response.to_json
    end

    ## Create an Inbox task
    def add_to_provider_inbox(providerID, businessID, docID, subject, body, token, docType)
        begin
            LOG.debug "docType: #{docType}"
            options = params.merge(provider: providerID, business_entity: businessID, handler: docID, subject: subject, body: body, token: token, docType: docType)
            response = JSON.parse(post("#{TASK_SERVICE_URL}/tasks", options))
            LOG.debug "Create Task response: #{res.inspect}"
            return response['taskid']
        rescue Exception => e
            LOG.error "Error Creating Inbox task: #{e.message}"
            return nil
        end
    end

end
