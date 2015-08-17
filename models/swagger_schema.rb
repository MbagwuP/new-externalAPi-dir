class SwaggerSchema

  PUBLIC_DOCS_OPTIONS   = {
    include_authorization:        false,
    add_base_path_to_pathname:    false,
    add_base_path_to_http_proxy:  false,
    remove_swagger_base_path:     false,
    include_amazon_fields:        false,
    name_by_environment:          false,
    include_deprecated_paths:     false,
    include_v1_paths:             false,
    include_misc_paths:           false,
    include_redirect_paths:       false,
    remove_definition_references: false,
    remove_post_body_params:      false,
    fill_in_allowed_responses:    false
  }
  AMAZON_IMPORT_OPTIONS = {
    include_authorization:        true,
    add_base_path_to_pathname:    true,
    add_base_path_to_http_proxy:  true,
    remove_swagger_base_path:     true,
    include_amazon_fields:        true,
    name_by_environment:          true,
    include_deprecated_paths:     true,
    include_v1_paths:             true,
    include_misc_paths:           true,
    include_redirect_paths:       true,
    remove_definition_references: true,
    remove_post_body_params:      true,
    fill_in_allowed_responses:    true
  }
  AMAZON_ALLOWED_RESPONSE_CODES = [200, 201, 204, 400, 401, 403, 404, 422, 500, 502, 503]

  def initialize environment_url, docs_yml_path, options
    @environment_url, @docs_yml_path = environment_url, docs_yml_path
    if options.is_a?(Symbol)
      options = (options == :amazon_import) ? AMAZON_IMPORT_OPTIONS : PUBLIC_DOCS_OPTIONS
    end
    # @environment_url = 'https://4c4ad952.ngrok.com/v2'
    # @environment_url = 'https://api-qa.carecloud.com/v2'
    # @docs_yml_path = 'api-docs'
    options.each {|k,v| instance_variable_set("@#{k}", v)}
  end

  def build
    base        = yml_with_erb_to_hash "#{@docs_yml_path}/base.yml"
    definitions = yml_with_erb_to_hash "#{@docs_yml_path}/definitions.yml"

    processed_paths = {}
    processed_paths.merge! process_paths('paths.yml', '/v2')
    processed_paths.merge! process_paths('paths_v1.yml', '/v1') if @include_v1_paths
    processed_paths.merge! process_paths('paths_misc.yml', '') if @include_misc_paths
    processed_paths.merge! process_paths('paths_deprecated.yml', '/v2') if @include_deprecated_paths
    processed_paths.merge! process_paths('paths_redirect.yml', '') if @include_redirect_paths

    base['paths']       = processed_paths
    base['paths']       = Hash[processed_paths.sort]
    if @remove_definition_references
      base.delete('definitions')
    else
      base['definitions'] = definitions
    end

    if @name_by_environment
      base['info']['title']       = 'External API ' + ENV['RACK_ENV']
      base['info']['description'] = 'External API ' + ENV['RACK_ENV']
    end
    if @remove_swagger_base_path
      base.delete('basePath')
    end

    @schema_hash = base
  end

  def process_paths paths_yml_file, basePath
    require 'pry-rescue'
    Pry.rescue do

    processed_paths = {}

    paths = yml_with_erb_to_hash "#{@docs_yml_path}/#{paths_yml_file}"
    return {} if !paths

    paths.keys.each do |path|
      processed_paths[path] = paths[path]
      paths[path].keys.each do |method|
        # add a parameters field if there is none
        # add an Authorization header to each endpoint
        if @include_authorization
          parameters = paths[path][method]["parameters"] || []
          if basePath == '/v1'
            parameters << {name: "authentication", in: "query", required: true, type: "string"}
          elsif basePath == '/v2'
            parameters << {name: "Authorization", in: "header", required: true, type: "string"}
          end
          processed_paths[path][method]["parameters"] = parameters
        end
        if @include_amazon_fields
          processed_paths[path][method]['x-amazon-apigateway-integration'] = {
            'type'              => 'http',
            'uri'               => @environment_url + (@add_base_path_to_http_proxy ? basePath : nil) + path,
            'httpMethod'        => method.upcase,
            'responses'         => amazon_responses_section,
            'requestParameters' => request_parameters_section(processed_paths[path][method]['parameters'], basePath)
          }.compact
          # if basePath == '/v1'
            # processed_paths[path][method]['x-amazon-apigateway-integration'].delete('requestParameters')
            # processed_paths[path][method]['x-amazon-apigateway-integration']['requestParameters'] = {
            #   'integration.request.query.authentication' => 'method.request.query.authentication'
            # }
          # end
        else
          processed_paths[path][method].delete('x-amazon-apigateway-integration')
        end
        if @remove_definition_references
          # remove "schema" keys from responses
          path_response_codes = processed_paths[path][method]['responses'].keys
          path_response_codes.each do |code|
            processed_paths[path][method]['responses'][code].delete('schema')
          end
          # remove "schema" keys from requests
          if processed_paths[path][method]['parameters'].any?
            (0..(processed_paths[path][method]['parameters'].length - 1)).each do |param_index|
              processed_paths[path][method]['parameters'][param_index].delete('schema')
            end
          end
        end
        if @remove_post_body_params
          if processed_paths[path][method]['parameters'].any?
            (0..(processed_paths[path][method]['parameters'].length - 1)).each do |param_index|
              processed_paths[path][method]['parameters'].delete_at(param_index) if processed_paths[path][method]['parameters'][param_index]['in'] == 'body' rescue nil
            end
          end
        end
        if @fill_in_allowed_responses
          AMAZON_ALLOWED_RESPONSE_CODES.each do |code|
            if !processed_paths[path][method]['responses'].keys.include?(code)
              # if this code is a 2xx, check to see if there already is one for this path
              # if it's not a 2xx, just add it
              # AWS Swagger import tool blows up if there's more than one 2xx in a path
              if [200, 201, 204].include?(code)
                if !(processed_paths[path][method]['responses'].keys & [200, 201, 204]).any?
                  processed_paths[path][method]['responses'][code] = {description: 'filled in automatically for passthrough'}
                end
              else
                processed_paths[path][method]['responses'][code] = {description: 'filled in automatically for passthrough'}
              end
            end
          end
        end
      end
      if @add_base_path_to_pathname
        processed_paths.rename_key(path, basePath + path) unless basePath.empty?
      end
    end

    processed_paths
    end
  end

  def request_parameters_section parameters, basePath
    entries = {}
    entries['integration.request.header.Authorization'] = 'method.request.header.Authorization' if basePath == '/v2'

    # make sure all path params get sent through in the Integration Request section so they will show up for the HTTP Proxy endpoint
    unless parameters.nil?
      path_params = parameters.map{|x| x['name'] if x['in'] == 'path'}.compact
      path_params.each do |x|
        entries["integration.request.path.#{x}"] = "method.request.path.#{x}"
      end

      query_params = parameters.map{|x| x['name'] if x['in'] == 'query'}.compact
      query_params.each do |x|
        entries["integration.request.querystring.#{x}"] = "method.request.querystring.#{x}"
      end

      header_params = parameters.map{|x| x['name'] if x['in'] == 'header'}.compact
      header_params.each do |x|
        entries["integration.request.header.#{x}"] = "method.request.header.#{x}"
      end
    end

    entries
  end

  def amazon_responses_section
    return @amazon_responses_section if defined?(@amazon_responses_section) # caching
    section = {}
    AMAZON_ALLOWED_RESPONSE_CODES.each { |code| section[code.to_s] = {statusCode: code.to_s} }
    @amazon_responses_section = section
  end

  def remove_blank_path_parameters_fields
    nil
    # the Amazon API Gateway Swagger Import tool blows up with a null pointer exception if this is null
  end

  def to_h
    build
    @schema_hash
  end

  def to_json
    build
    @schema_hash.to_json
  end

  def yml_with_erb_to_hash file_path
    # don't bother with ERB for now, looks like we may not need it
    # YAML.load(ERB.new(File.read(file_path)).result)
    YAML.load_file file_path
  end

end
