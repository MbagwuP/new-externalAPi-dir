#
# File:       inbound_mail_service
#
#
# Version:    1.0
#

# Use the following to test locally
#curl --form to=johnw --form subject=sub --form cc=cc_jw,cc_jjw --form attachments=2 --form text="hello john" --form attachment1=@toss.jpg --form attachment2=@toss2.jpg localhost:1234/inbound_mail

class ApiService < Sinatra::Base
    
    post '/inbound_mail' do

        # hack to get Token
        urlauth  = API_SVC_URL + 'login.json?login=interface@interface.com&password=welcome'
        resp = RestClient.get(urlauth)
        parsed = JSON.parse(resp.body)
        token = CGI::unescape(parsed["authtoken"])
        LOG.debug "Token:#{token}"

        begin
            num_attachments = params['attachments'].to_i
            
            LOG.debug "To: #{params['to']} CC: #{params['cc']} From: #{params['from']} Subject: #{params['subject']}"
            LOG.debug "Body: #{params['text']}"
            LOG.debug "Body(html): #{params['html']}"
            LOG.debug "# attachments: #{num_attachments}"
            
            providers = []
            params['to'].split(',').collect {|c| providers << c.strip} if !params['to'].nil?
            params['cc'].split(',').collect {|c| providers << c.strip} if !params['cc'].nil?
            
            providers.each do |provider|
            
                LOG.debug "Processing #{provider}"
                # Find provider and BE based on To: / CC: fields
                # next if provider NOT FOUND

                # Loop through the attachments; upload to DMS and Create a Task in the providers Inbox
                i = 1
                while i <=  num_attachments
                    begin
                        temp_file = Tempfile.new('inbound')         # Do immediately so exception handler doesn't error
                    
                        attachment_name = "attachment#{i}"
                        document_binary = params[attachment_name][:tempfile]
                        document_name = params[attachment_name][:filename]
                        extname = File.extname(document_name)
                        
                        if extname != '.jpg' && extname != '.pdf'
                            LOG.error "Skipping #{document_name}, must be of type PDF or JPG"
                        else
                            LOG.debug "Processing #{document_name}"

                            # Save file locally
                            document_binary.rewind
                            File.open(temp_file, "wb") do |file|
                                file.write(document_binary.read)
                            end

                            # Now upload to DMS
                            response = dms_upload(temp_file, token)
                            handler_id = response["nodeid"]
                            LOG.debug "Got DMS handler id: #{handler_id}"

                            # Now create a task in the respective inbox
                        end

                    rescue Exception => e
                        LOG.error "Error processing #{attachment_name}: #{e.message}"

                        # Swallow all exceptions and move onto next record
                    end

                    # Little Housekeeping
                    File.delete(temp_file) if File.exists?(temp_file)

                    i += 1
                end
            end

        rescue Exception => e
            LOG.error "Inbound_mail Error: #{e.message}"
        end

        LOG.debug "Success"
        # Failure to return 200 will cause Sendgrid to retry until 200 is received.
        status HTTP_OK
    end

end
