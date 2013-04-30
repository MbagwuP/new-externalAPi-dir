#
# File:       healthchecks.rb
#
#
# Version:    1.0
#

class ApiService < Sinatra::Base

    
    # perform_healthcheck
    #
    # 

    def perform_healthcheck
        
        # check to see if we can talk to the DB
        
        begin
            cert = nil
        rescue => e
            LOG.error ("Healthcheck failed #{e.message})")
            cert = nil
        end
        
        db_health = {   "description" => "Check Pass Service database connection",
                        "faultSeverity" => "CRITICAL",
                        "status" => { "result" => (cert ? "OK" : "FAILED") }
        }

        health = {  "applicationName" => "ApiService",
                    "systemStatus" => (cert ? "The system is currently up and healthy." : "The system is currently up but BROKEN"),
                    "healthStatus" => (cert ? "HEALTHY" : "BROKEN"),
                    "loadbalancerStatus" => (cert ? "UP" : "DOWN"),
                    "serverStatusBean" => (cert ? "UP" : "DOWN"),
                    "healthchecks" => { "databaseHealthCheck" => db_health }
        }

        health.to_json

    end
    
    # HealthCheck
    #
    # GET /healthcheck
    #
    
    get '/healthcheck' do
    
        perform_healthcheck
        
    end

    # Load Balancer Status
    #
    # GET /lb_status
    #

    get '/lb_status' do
        
        health = JSON.parse(perform_healthcheck)
        
        health["loadbalancerStatus"].downcase   
        
    end

    # Healthcheck ping
    #
    # GET /healthcheck_ping
    #

    get '/healthcheck_ping' do
        
        "pong"
        
    end

end
