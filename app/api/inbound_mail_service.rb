#
# File:       inbound_mail_service
#
#
# Version:    1.0
#

class ApiService < Sinatra::Base
    
    
    post '/inbound_mail' do

        request_body = get_request_JSON
        puts request_body

    end

end
