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

      app.before %r{^(?!/v2/api-docs$)} do
        cache_control :no_store
      end

      # # Control the level of logging based on settings
      app.before do
        # ensure all responses are JSON, unless specified otherwise on a per-endpoint basis
        content_type 'application/json', :charset => 'utf-8'

        # to handle patientid param like patient_id
        params[:patient_id] = params[:patientid] if params[:patientid].present?

        if current_internal_request_header
          authentication_filter
        end

        #   @start_time = Time.now
        #
        #   auditoptions = {
        #       :ip => "#{request.ip}",
        #       :request_method => "#{request.request_method}",
        #       :path => "#{request.fullpath}"
        #   }
        #
        #   audit_log(AUDIT_TYPE_TRANS, SEVERITY_TYPE_LOG, auditoptions)
        #
      end

      app.after do
        #request_duration = ((Time.now - @start_time) * 1000.0).to_i
        statuscode = @statuscode || response.status

        ## todo: get who the user is
        #auditoptions = {
        #    :ip => "#{request.ip}",
        #    :statuscode => "#{statuscode}",
        #    :duration => "#{request_duration} ms",
        #    :request_method => "#{request.request_method}",
        #    :request_path => "#{request.fullpath}"
        #}

        #audit_log(AUDIT_TYPE_TRANS, SEVERITY_TYPE_LOG, auditoptions)

        if statuscode >= HTTP_BAD_REQUEST
          NewRelic::Agent.notice_error(@message)
          ApiService::LOG.warn("----#{request.ip} \"#{request.request_method} #{request.fullpath}\" - #{statuscode} #{@message}")
        else
          ApiService::LOG.info("----#{request.ip} \"#{request.request_method} #{request.fullpath}\" - #{statuscode} #{@message}")
        end
      end

      app.before /\/(?<api_version>v1|v2)\/*/ do |version|
        ::NewRelic::Agent.add_custom_attributes({
                                                  business_entity_id: oauth_request? ? current_business_entity : nil,
                                                  application_id:     oauth_request? ? current_application : nil,
                                                  api_version:        version,
                                                  token:              params['authentication'] || env['HTTP_AUTHORIZATION']
        }.compact)
      end
    end

  end

  register ApplicationFilters
end
