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
       
        rescue Exception => e
            LOG.error "Inbound_mail Error: #{e.message}"
        end

        # Failure to return 200 will cause Sendgrid to retry until 200 is received.
        status HTTP_OK
    end

end
