require 'cgi'
require 'json'

module HealthCheck

  class Middleware
    VITAL_PATH = /\A\/health_check(\.html|\.json|\.txt)?\z/
    PING_PATH = /\A\/ping(\.html|\.json|\.txt)?\z/
    LB_PATH = /\A\/lb_check(\.html|\.json|\.txt)?\z/

    def initialize(app, options={})
      @app = app
      @path = options.fetch(:path, VITAL_PATH)
      @description = options.fetch(:description, {
        service: "Service Health Check",
        description: "Health Check",
        version: "0.1"
      })
    end

    def call(env)
      path = env['PATH_INFO']
      process(path, env) || @app.call(env)
    end

    protected

    def process(path, env)
      params = Rack::Utils.parse_nested_query(env['QUERY_STRING'])
      if path_matches?(path, @path)
        result = HealthCheck.execute(@description)
        # NOTE: Default all resulting to JSON format
        # mime = determine_mime_type(path)
        # body = case mime
        #        when "application/json" then render_json(result)
        #        when "text/plain" then render_text(result)
        #        else render_html(result)
        #        end
        with_callback = params.has_key?('callback') && !params['callback'].blank?
        mime = with_callback ? "application/javascript" : "application/json"
        body = with_callback ? render_callback(result, params['callback']) : render_json(result)
        # [result.success? ? 200 : 500, {'Content-Type' => "#{mime}; charset=utf-8"}, [body]]
        [200, {'Content-Type' => "#{mime}; charset=utf-8"}, [body]]
      elsif path_matches?(path, LB_PATH)
        result = HealthCheck.execute(@description)
        [200, {}, [result.body[:service_status]]]
      elsif path_matches?(path, PING_PATH)
        [200, {}, ['pong']]
      end
    end

    def determine_mime_type(path)
      case path.split('.').last.downcase
      when 'json' then 'application/json'
      when 'txt' then 'text/plain'
      else 'text/html'
      end
    end

    def path_matches?(path, matcher)
      case matcher
      when Proc then matcher.call(path)
      when Regexp then path =~ matcher
      else matcher.to_s == path
      end
    end

    def render_json(result)
      body = result.body
      dependencies = result.records.flatten(1).map do |name, status, comment, level, details|
        payload = {name: name, status: status, comment: comment, level: level}
        payload.merge!({details: details}) if details
        payload
      end if result.records
      body.merge!({dependencies: dependencies}) if dependencies.any?
      body.to_json
    end

    def render_callback(result, callback='callback')
      "#{callback}(#{render_json(result)});"
    end

    def render_text(results)
    end

    def render_html(results)
    end

  end

end
