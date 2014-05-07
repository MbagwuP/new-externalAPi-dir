module Sinatra
  module ApplicationFilters
    
    # http://www.sinatrarb.com/intro.html#Filters
    # Filters are methods that are run before or after a request
    
    # Examples:

    # "Before" filters may halt the request cycle. A common "before" filter is one which requires that a user is logged in for an action to be run
    
    # app.before do
    #   # logger.info "This fires before every call" 
    # end
    
    # Filters optionally take a pattern, causing them to be evaluated only if the request path matches that pattern:
    # app.before '/foo/bar' do
      # logger.info "This fires on calls to /foo/bar only" 
    # end
    
    # app.before %r{\/foo\/([a-zA-Z0-9\-\_]+)\/(bar|baz)\z} do
      # logger.info "This fires on calls to /foo/<id>/bar and /foo/<id>/baz"
    # end

    # "After" filters are evaluated after each request within the same context and can also modify the request and response. 
    # Instance variables set in before filters and routes are accessible by after filters:
    # app.after do 
      # logger.info "This fires after every request" 
    # end
    
    def self.registered(app)
      # define filters here
    end
    
  end

  register ApplicationFilters
end