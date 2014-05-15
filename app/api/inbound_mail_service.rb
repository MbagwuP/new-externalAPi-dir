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
            LOG.debug request.body
            
            request_body = get_request_JSON
            LOG.debug(request_body)
        rescue Exception => e
            LOG.error "Inbound_mail Error: #{e.message}"
        end

        status HTTP_OK
    end

end
