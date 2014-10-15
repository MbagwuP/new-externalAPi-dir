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
                # Find User and BE based on recipients
                user = JSON.parse(find_user_by_email(recipient, token))
                next if user.nil?
                
                # Loop through the attachments; upload to DMS and Create a Task in the Users' Inbox
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
                            page_count = response['metadata']['pages']
                            LOG.debug "DMS handler id: #{docID}"

                            # Create a task in the respective inbox
                            # Use "from" field to differeniate Inbound Fax vs other documents
                            #if JSON.parse(params['envelope'])['from'][0] == 'faxserver@carecloud.com'
                            #    docType = 'Fax'
                            #else
                            #    docType = 'Document'
                            #end
                            #taskID = add_to_user_inbox(user['userID'], user['business_entity_id'], docID, params['subject'], params['text'], token, docType)
                            #LOG.debug "Task id: #{taskID}"

                            from = JSON.parse(params['envelope'])['from'][0]
                            to = recipient
                            subject = params['subject']

                            add_to_inbound_documents(docID, from, to, subject, page_count, token)
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
                    taskID = add_to_user_inbox(user['userID'], user['business_entity_id'], nil, params['subject'], params['text'], token, 'Tickler')
                    LOG.debug "Task id: #{taskID}"
                end
            end
        rescue Exception => e
            LOG.error "Inbound_mail Error: #{e.message}"
        end

        # Failure to return 200 will cause Sendgrid to retry until 200 is received.
        status HTTP_OK
    end

    ## Using the recipient email address find the userID & business entity
    def find_user_by_email (recipient, token)
        begin
            response = RestClient.get("#{API_SVC_URL}/business_entities/list_by_user.json?list_type=list&token=#{token}")
            LOG.debug response.body
            parsed = JSON.parse(response.body)['business_entities']
            userID = parsed[0]['user_profile_id']
            userID = 31495
            business_entity_id = parsed[0]['id']
            response = {:userID => userID, :business_entity_id => business_entity_id}
            return response.to_json
        rescue Exception => e
            LOG.error "Error find_user_by_email: #{e.message}"
            return nil
        end
    end

    ## Create an Inbox task
    def add_to_user_inbox(userID, business_entity_id, docID, subject, body, token, docType)
        begin
            task =  {:name => subject, :description => body, :due_at => '2011-04-08 02:46:32', :business_entity_id => business_entity_id, :task_request_type_id => 98}
            request_body = {:task => task}
            LOG.debug "POST #{API_SVC_URL}/businesses/#{business_entity_id}/users/#{userID}/tasks.json?token=#{token}"
            response = RestClient.post("#{API_SVC_URL}/businesses/#{business_entity_id}/users/#{userID}/tasks.json?token=#{token}", request_body.to_json, :content_type => :json)
            parsed = JSON.parse(response.body)
            return parsed['task']['id']
        rescue Exception => e
            LOG.error "Error Creating Inbox task: #{e.message}"
            return nil
        end
    end

    ## Create an Inbox task
    def add_to_inbound_documents( doc_id, from, to, subject, page_count, token)
      begin
        doc =  {:from => from, :to => to, :subject => subject, :page_count => page_count, :document_handler => doc_id}
        request_body = {:doc => doc}
        LOG.debug ""
        response = RestClient.post("#{API_SVC_URL}/documents/inbound.json?token=#{token}", request_body.to_json, :content_type => :json)
        parsed = JSON.parse(response.body)
        return parsed
      rescue Exception => e
        LOG.error "Error Creating Inbox task: #{e.message}"
        return nil
      end
    end

end
