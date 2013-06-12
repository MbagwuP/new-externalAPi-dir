#
# File:       healthchecks.rb
#
#
# Version:    1.0
#

class ApiService < Sinatra::Base

    
    # perform_healthcheck
    #
    def perform_healthcheck
        
        # check to see if we can talk to the DB
        webserviceUp = false
        cacheUp = true
        mongoUp = false
        docStoreUp = false

        ## WebService
        begin

            server = API_SVC_URL
            #server = "dev.carecloud.local"

            ping_count = 10
            result = `ping -q -c #{ping_count} #{server}`

            if ($?.exitstatus == 0)
              webserviceUp = true
            end

        rescue Exception => e
            LOG.fatal e
            webserviceUp = false
        end

        ## Cache
        begin
            settings.cache.set("testvalue", "12346", 20)
            newvalue = settings.cache.get("testvalue")

            if newvalue != "12346"
                cacheUp = false
            end
        rescue Exception => e
            cacheUp = false
        end

        ## Mongo
        begin
            if !MONGO.nil?
                mongoUp = true
            end
        rescue Exception => e
            mongoUp = false
        end

        ## Doc Store
        begin
            server = DOC_SERVICE_URL

            ping_count = 10
            result = `ping -q -c #{ping_count} #{server}`

            if ($?.exitstatus == 0)
              docStoreUp = true
            end

        rescue Exception => e
            LOG.fatal e
            docStoreUp = false
        end

        health = {  "applicationName" => "ApiService",
                    "webserviceHealth" => (webserviceUp ? "UP" : "DOWN"),
                    "cacheHealth" => (cacheUp ? "UP" : "DOWN"),
                    "nosqlStorageHealth" => (mongoUp ? "UP" : "DOWN"),
                    "documentStorageHealth" => (docStoreUp ? "UP" : "DOWN")
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
