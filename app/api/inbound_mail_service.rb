#
# File:       inbound_mail_service
#
#
# Version:    1.0
#

class ApiService < Sinatra::Base
    
    
    post '/inbound_mail' do

        LOG.debug "Got send mail message"
        
        begin
            to = params['to']
            cc = params['cc']
            from = params['from']
            subject = params['subject']
            body = params['text']
            num_attachments = params['attachments']
            LOG.debug "To: #{to} CC: #{cc} From: #{from} Subject: #{subject} Body: #{body}"
       
        rescue Exception => e
            LOG.error "Inbound_mail Error: #{e.message}"
        end

        status HTTP_OK
    end

end
