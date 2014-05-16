#
# File:       inbound_mail_service
#
#
# Version:    1.0
#

class ApiService < Sinatra::Base
    
    
    post '/inbound_mail' do

        begin
            headers = params['headers']
            to = params['to']
            cc = params['cc']
            from = params['from']
            subject = params['subject']
            body = params['text']
            body_html = params['html']
            num_attachments = params['attachments']
            
            #LOG.debug "Headers: #{headers}"
            LOG.debug "To: #{to} CC: #{cc} From: #{from} Subject: #{subject}"
            LOG.debug "Body: #{body}"
            LOG.debug "Body(html): #{body_html}"
            LOG.debug "# attachments: #{num_attachments}"
            
            # Should be a param attachmentX for each attachment
            # Need to scan these into the system
            
            i = 1
            while i <=  num_attachments
                attachment_name = 'attachment' + i
                LOG.debug "Processing #{attachment_name}"
                document_binary = params[attachment_name][:tempfile]
                document_name = params[attachment_name][:filename]
                extname = File.extname(document_name)
                LOG.debug "# document_name: #{document_name}"
                
                if extname != '.jpg' && extname != '.pdf'
                    LOG.error 'Document must be of type PDF or JPG' if file_type.match(document_type_regex) == nil
                end

                # save file locally
                temp_file = Tempfile.new('inbound')
                document_binary.rewind
                File.open(temp_file, "wb") do |file|
                    file.write(document_binary.read)
                end

                # Now upload to DMS
                response = dms_upload(temp_file, pass_in_token)
                handler_id = response["nodeid"]
                LOG.debug "Got DMS handler  id: #{handler_id}"

                File.delete(temp_file) if File.exists?(temp_file)

                # Now create a task in the respective inbox

                i += 1
            end
       
        rescue Exception => e
            LOG.error "Inbound_mail Error: #{e.message}"
        end

        # Failure to return 200 will cause Sendgrid to retry until 200 is received.
        status HTTP_OK
    end

    ## upload the document to the DMS server
    def dms_upload (file_path, token, params = {})
        file = File.new(file_path, 'rb')
        options = params.merge(file: file, token: token)
        res = JSON.parse(post("#{DOC_SERVICE_URL}/documents", options))
        LOG.debug "Dms::DocumentAPI upload response: #{res.inspect}"
        return res
    end

end
