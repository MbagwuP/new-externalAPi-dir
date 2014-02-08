#
# File:       healthchecks.rb
#
#
# Version:    1.0
#
#(git clone git@smoke.carecloud.com:ruby/sinatra/external_api)
#(/etc/init.d/nginx restart)
#api_internal_svc_url: http://localservices.carecloud.local:3000/

class ApiService < Sinatra::Base
    
    
    # perform_healthcheck
    #
    def perform_healthcheck
        
        # check to see if we can talk to the DB
        webserviceUp = false
        cacheUp = false
        mongoUp = false
        docStoreUp = false
        
        ## WebService
        begin
            
            uri = URI.parse(API_SVC_URL)
            conn = Net::HTTP::get_response(uri)
            
            ## check basic endpoind devservices.carecloud.local/
            ## replace when ruby app has healthcheck
            webserviceUp = true if (conn.code.to_s == "403" || conn.code.to_s == "200")
            
        rescue Exception => e
            webserviceUp = false
        end
        
        ## Cache
        begin
            settings.cache.set("testvalue", "12346", 20)
            newvalue = settings.cache.get("testvalue")
            
            cacheUp = false if newvalue != "12346"
                
        rescue Exception => e
            cacheUp = false
        end
        
        ## Audit Log (Mongo)
        begin
            mongoUp = true
            auudtevents = CareCloud::AuditRecord.where(:uuid => 0).first
        rescue => e
            mongoUp = false
        end

        ## DMS
        begin
            
            urlToUse = "#{DOC_SERVICE_URL}/api/explorer"
            
            uri2 = URI.parse(urlToUse)
            conn2 = Net::HTTP::get_response(uri2)
            
            docStoreUp = true if (conn2.code.to_s == "200")
            
        rescue Exception => e
            docStoreUp = false
        end
        
        ws_health = {"name" => "Web Service",
            "description" => "Web Service",
            "status" => (webserviceUp ? "HEALTHY" : "BROKEN")
        }
        
        cache_health = {"name" => "MemCache",
            "description" => "memcached",
            "status" => (cacheUp ? "HEALTHY" : "IMPAIRED")
        }
        
        mongo_health = {"name" => "Audit",
            "description" => "MongoDB for auditing",
            "status" => (mongoUp ? "HEALTHY" : "IMPAIRED")
        }
        
        dms_health = {"name" => "DMS",
            "description" => "DMS",
            "status" => (docStoreUp ? "HEALTHY" : "BROKEN")
        }
        
        overal_health = true
        overal_health = webserviceUp && mongoUp && docStoreUp
        
        dependencychecks = []
        dependencychecks << ws_health
        dependencychecks << cache_health
        dependencychecks << mongo_health
        dependencychecks << dms_health
        
        health = {"service" => "External API Service",
            "description" => "Service 3rd party applications utilize to access CareCloud",
            "version" => "#{SOFTWARE_VERSION}",
            "serviceStatus" => (overal_health ? "HEALTHY" : "BROKEN"),
            "loadbalancerStatus" => (overal_health ? "UP" : "DOWN"),
            "dependencychecks" => dependencychecks
        }
        
        health.to_json
        
    end
    
    # HealthCheck
    #
    # GET /healthcheck
    #
    
    get '/healthcheck' do
    
    # Need to handle jQuery requests
    if params[:callback]
        health = perform_healthcheck
        return "#{params[:callback]}(#{health})"
    else
        perform_healthcheck
    end

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