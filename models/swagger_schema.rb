# SwaggerSchema
# This class programatically loads up all the YML files, makes appropriate modifications depending on circumstances that you define, 
# and then generates a complete Swagger schema (swagger.json file)
# For example, every endpoint defined in paths.yml will automatically have the Authorization header included, since they are all v2. 
# Every endpoint defined in paths_v1.yml will automatically have the `authentication` query string parameter included, since they are all v1.

# The generated Swagger schema file is then used for:
# * swagger docs in the developer portal
# * import into AWS API Gateway using AWS' swagger import tool: https://github.com/awslabs/aws-apigateway-importer

# See Confluence for more documentation on this class:
# http://confluence.carecloud.com/pages/viewpage.action?pageId=9797725

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
    include_duplicates_paths:     false,
    include_misc_paths:           false,
    include_redirect_paths:       false,
    remove_definition_references: false,
    remove_post_body_params:      false,
    fill_in_allowed_responses:    false,
    specify_host:                 true,
    process_definitions:          true, 
    corsify_paths:                false
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
    include_duplicates_paths:     true,
    include_misc_paths:           true,
    include_redirect_paths:       true,
    remove_definition_references: true,
    remove_post_body_params:      true,
    fill_in_allowed_responses:    true,
    specify_host:                 false,
    process_definitions:          false, 
    corsify_paths:                true
  }
  AMAZON_ALLOWED_RESPONSE_CODES = [200, 201, 204, 301, 400, 401, 403, 404, 409, 422, 423, 500, 502, 503, 513]
  AMAZON_CORS_ALLOWED_METHODS   = ['GET', 'POST', 'PUT', 'DELETE']

  def initialize environment_url, docs_yml_path, options, cors_url=nil
    @environment_url, @docs_yml_path, @cors_url = environment_url, docs_yml_path, cors_url
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

    base['host'] = @environment_url.gsub('https://','').gsub('http://','') if @specify_host

    processed_paths = {}
    processed_paths.merge! process_paths('paths.yml', '/v2')
    processed_paths.merge! process_paths('paths_duplicates.yml', '/v2') if @include_duplicates_paths # old URLs that we were previously supporting via regexes
    processed_paths.merge! process_paths('paths_v1.yml', '/v1') if @include_v1_paths
    processed_paths.merge! process_paths('paths_misc.yml', '') if @include_misc_paths
    processed_paths.merge! process_paths('paths_deprecated.yml', '/v2') if @include_deprecated_paths
    processed_paths.merge! redirectify_paths('paths_redirect.yml') if @include_redirect_paths

    processed_paths = corsify_paths(processed_paths) if @corsify_paths

    base['paths']       = processed_paths
    base['paths']       = Hash[processed_paths.sort]
    if @remove_definition_references
      base.delete('definitions')
    else
      if @process_definitions
        base['definitions'] = process_definitions(definitions)
      else
        base['definitions'] = definitions
      end
    end

    if @name_by_environment
      base['info']['title']       = 'External API ' + ENV['RACK_ENV'] + ' ' + Time.now.to_s[0..-10]
      base['info']['description'] = 'External API ' + ENV['RACK_ENV']
    end
    if @remove_swagger_base_path
      base.delete('basePath')
    end

    @schema_hash = base
  end

  def process_paths paths_yml_file, basePath
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
            parameters << {'name' => "authentication", 'in' => "query", 'required' => true, 'type' => "string"}
          elsif basePath == '/v2'
            parameters << {'name' => "Authorization", 'in' => "header", 'required' => true, 'type' => "string"}
          end
          processed_paths[path][method]["parameters"] = parameters
        
          # allow internal request headers for event publishing
          business_entity_guid_header = {
            'name' => 'X-Business-Entity-GUID',
            'in' => 'header',
            'required' => false,
            'type' => 'string'
          }
  
          content_type_header = {
            'name' => 'Content-Type',
            'in' => 'header',
            'required' => false,
            'type' => 'string'
          }
  
          date_stamp_header = {
            'name' => 'Date',
            'in' => 'header',
            'required' => false,
            'type' => 'string'
          }
  
          parameters << business_entity_guid_header
          parameters << date_stamp_header
          parameters << content_type_header
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
            processed_paths[path][method]['responses'][code][:headers] = cors_headers if processed_paths[path][method]['responses'][code]
          end
        end
        if @include_amazon_fields
          # require 'pry'; binding.pry
          response_codes = processed_paths[path][method]['responses'].keys
          processed_paths[path][method]['x-amazon-apigateway-integration'] = {
            'type'               => 'http',
            'uri'                => @environment_url + (@add_base_path_to_http_proxy ? basePath : nil) + path,
            'httpMethod'         => method.upcase,
            'responses'          => amazon_responses_section(processed_paths[path][method]['responses']),
            'requestParameters'  => request_parameters_section(processed_paths[path][method]['parameters'], basePath)
            # 'responseParameters' => processed_paths[path][method]['parameters']
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
      end
      if @add_base_path_to_pathname
        processed_paths.rename_key(path, basePath + path) unless basePath.empty?
      end
    end

    processed_paths
  end

  # Workaround for changing the yaml definitions FROM:
  #
  #     properties:
  #       field1: array
  #       field2:
  #         type: array
  #         $ref: Definition
  # 
  # TO:
  #     properties:
  #       field1:
  #         type: array 
  #         items:
  #           string
  #       field2:
  #         type: array
  #         items:
  #           $ref: Definition
  #
  def process_definitions(definitions)
    definitions.map do |model, hash|
      hash['type'] = 'object'
      next unless hash['properties']
      # set all fields to required by default
      hash['required'] = hash['properties'].keys
      # format the definitions
      hash['properties'].map do |k, v| 
        if v.is_a?(String)
          if v == 'array'
            hash['properties'][k] = { 'type'=> 'array', 'items' => {'type' => 'string'} }
          else
            hash['properties'][k] =  { 'type' => v }
          end
        end

        if v['$ref'] && v['type'] == 'array'
          v['items'] =  { '$ref' => v.delete('$ref') }
        end
      end
    end
    definitions
  end

  def cors_headers
    { 
      'Access-Control-Allow-Headers' => {type: "string"}, #'integration.response.header.Access-Control-Allow-Headers',
      'Access-Control-Allow-Methods' => {type: "string"}, #wrap_in_single_quotes(AMAZON_CORS_ALLOWED_METHODS.join(',')),
      'Access-Control-Allow-Origin'  => {type: "string"}
    }
  end

  def corsify_paths paths
    corsified_paths = {}
    paths.keys.each do |path|
      corsified_paths[path] = paths[path]
      corsified_paths[path]['options'] = {
        'responses' => {
          '200' => { headers: cors_headers }
        },
        'x-amazon-apigateway-integration' => {
          'type'               => 'mock',
          'uri'                => @environment_url + path,
          'httpMethod'         => 'OPTIONS',
          'requestTemplates' => {"application/json" => "{'statusCode': 200}"},
          'responses'          => {'200' => {
            'statusCode' => '200',
            'responseParameters' => cors_response_parameters.merge((paths[path]['responses']['200']['responseParameters'] rescue nil) || {}), # this stuff isn't necessary for Link, it's just for OPTIONS,
            # 'responseTemplates' => {"application/json" => '{"statusCode": 200}'} # this wasn't necessary, but refer to this format in case we ever need responseTemplates
          }}
          # 'requestParameters'  => request_parameters_section(processed_paths[path][method]['parameters'], basePath)
          # 'responseParameters' => response_parameters_section(processed_paths[path][method]['parameters'], response_codes)
        }.compact
      }
    end
    corsified_paths
  end

  def redirectify_paths paths_yml_file
    # do response parameter forwarding here
    # paths.keys.each do |path|
    #   processed_paths[path] = paths[path]
    #   paths[path].keys.each do |method|


          # parameters = paths[path][method]["parameters"] || []
          # parameters << {'name' => "authentication", 'in' => "query", 'required' => true, 'type' => "string"}
          # end
          # processed_paths[path][method]["parameters"] = parameters
    # processed_paths = {}

    paths = yml_with_erb_to_hash "#{@docs_yml_path}/#{paths_yml_file}"
    return {} if !paths
    redirectified_paths = {}

    paths.keys.each do |path|
      redirectified_paths[path] = paths[path]
      redirectified_paths[path]['get'] = {
        'parameters' => paths[path]['get']['parameters'],
        'responses' => {
          '301' => { headers: {Location: {type: "string"}} }
        },
        'x-amazon-apigateway-integration' => {
          'type'               => 'http',
          'uri'                => @environment_url + path,
          'httpMethod'         => 'GET',
          'responses'          => {'301' => {
            'statusCode' => '301',
            'responseParameters' => {
              'method.response.header.Location' => 'integration.response.header.Location'
            }
          }},
          'requestParameters'  => request_parameters_section(paths[path]['get']['parameters'], nil)
          # 'responseParameters' => response_parameters_section(processed_paths[path][method]['parameters'], response_codes)
        }
        }.compact
    end
    redirectified_paths
      # end
    # end
    # require 'pry'; binding.pry
    # paths
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

  # def response_parameters_section parameters, response_codes
  #   # require 'pry'; binding.pry
  #   entries = {}
  #   response_codes.each do |c|
  #     entries[c] = {}
  #     entries[c]['method.response.header.Access-Control-Allow-Headers'] = 'integration.response.header.Access-Control-Allow-Headers'
  #     entries[c]['method.response.header.Access-Control-Allow-Methods'] = AMAZON_CORS_ALLOWED_METHODS.join(',')
  #     entries[c]['method.response.header.Access-Control-Allow-Origin']  = @cors_url
  #   end
  #   entries
  # end

  def cors_response_parameters
    {
      # 'method.response.header.Access-Control-Allow-Headers' => 'integration.response.header.Access-Control-Allow-Headers',
      'method.response.header.Access-Control-Allow-Headers' => wrap_in_single_quotes("Content-Type, Authorization"),
      'method.response.header.Access-Control-Allow-Methods' => wrap_in_single_quotes(AMAZON_CORS_ALLOWED_METHODS.join(',')),
      'method.response.header.Access-Control-Allow-Origin'  => wrap_in_single_quotes(@cors_url)
    }
  end

  def amazon_responses_section upper_responses_section
    # upper_responses_section.symbolize_keys!
    section = {}
    AMAZON_ALLOWED_RESPONSE_CODES.each do |code|
      responseParameters = (upper_responses_section[code]['responseParameters'] rescue nil) || {}
      responseParameters.merge!(cors_response_parameters)

      headers = (upper_responses_section[code][:headers] rescue nil) || {}
      headers.merge!((upper_responses_section[code]['headers'] rescue nil) || {})

      section[code.to_s] = {
        'statusCode' => code.to_s,
        'headers' => headers,
          # 'Access-Control-Allow-Headers' => {type: "string"}, #'integration.response.header.Access-Control-Allow-Headers',
          # 'Access-Control-Allow-Methods' => {type: "string"}, #wrap_in_single_quotes(AMAZON_CORS_ALLOWED_METHODS.join(',')),
          # 'Access-Control-Allow-Origin'  => {type: "string"}  #wrap_in_single_quotes(@cors_url)
        # },
      # }
        'responseParameters' => responseParameters
      # }
      }
    end
    section
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

  def wrap_in_single_quotes str
    "'" + str + "'"
  end

end
