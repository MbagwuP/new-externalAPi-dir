#
# File:       document_service.rb
#
#
# Version:    1.0


class ApiService < Sinatra::Base


  DOCUMENT_TYPE_REGEX = '\Aapplication\/pdf'

  # Upload document to patient
  #
  # POST /v1/documents/<patientid>/upload?authentication=<authenticationToken>
  #
  # Params definition
  # :patientid     - the CareCloud patient identifier number
  #       (e.x.: patient-1234)
  # JSON Body
  # {
  #     "document": {
  #         "name": "test document",
  #         "format": "PDF",
  #         "description": "this is a test document"
  #     }
  # }
  # content-type: multipart/form-data
  # Example test command:
  #  curl -F "metadata=<documenttest.json" -F "payload=@example.pdf" http://localhost:9292/v1/documents/patient/patient-1819622/upload\?authentication\=
  # server action: Return status of upload
  # server response:
  # --> if document successfully uploaded: 201, with document id in response data
  # --> if not authorized: 401
  # --> if patient not found: 404
  # --> if bad request: 400
  post '/v1/documents/patient/:patientid/upload?' do

    ## parameters passed in
    LOG.debug(params[:metadata])
    LOG.debug(params[:payload])

    # Validate the input parameters
    request_body = JSON.parse(params[:metadata])

    validate_param(params[:patientid], PATIENT_REGEX, PATIENT_MAX_LEN)
    patientid = params[:patientid]

    ## token management. Need unencoded tokens!
    pass_in_token = URI::decode(params[:authentication])

    ## muck with the request based on what internal needs
    business_entity = get_business_entity(pass_in_token)

    #format to what the devservice needs
    patientid.slice!(/^patient-/)

    ## if external id, lookup internal
    patientid = get_internal_patient_id(patientid, business_entity, pass_in_token)

    # Now the picture is an IO object!
    document_binary = params[:payload][:tempfile]
    document_name = params[:payload][:filename]

    #rewind this file
    document_binary.rewind

    # Save the file
    # I end up having to save this local to post it again. I looked through a few articles to find out how to avoid
    # this but did not come back with a good answer. I would like to stream from input to POST. I leave this as a todo
    # For now steps:
    # get file, save local copy
    # post copy to alfresco
    # remove local copy
    internal_file_name = ''
    internal_file_name << patientid
    internal_file_name << '-'
    internal_file_name << rand(150).to_s
    internal_file_name << '-'
    internal_file_name << document_name

    LOG.debug(internal_file_name)
    File.open(internal_file_name, "wb") do |file|
      file.write(document_binary.read)
    end


    # http://stackoverflow.com/questions/51572/determine-file-type-in-ruby
    file_type = determine_file_type(internal_file_name)

    #application/pdf; charset=binary
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Document must be of type PDF"}' if file_type.match(DOCUMENT_TYPE_REGEX) == nil

    ## helpful articles
    ##   http://stackoverflow.com/questions/3938569/how-do-i-upload-a-file-with-metadata-using-a-rest-web-service
    ##   http://leejava.wordpress.com/2009/07/30/upload-file-from-rest-in-ruy-on-rail-with-json-format/
    ##
    ## Request test:
    ##   curl -F "metadata=<documenttest.json" -F "payload=@example.pdf" http://localhost:9292/v1/documents/patient/patient-1819622/upload\?authentication\=
    alfresco_upload(internal_file_name, pass_in_token)

    ## use rest client to do multipart form upload
    FileUtils.remove(internal_file_name)


    ## after upload completes, call to retrieve the node-id (handler)
    # curl http://uploads-dev.carecloud.local/documents/example.pdf/node-id\?token\=AQIC5wM2LY4SfczPZwSF0MGE2uTaM5NHZwC5vuNytaH7Wsk\=@AAJTSQACMDMAAlNLAAk1NzE0OTMzNTEAAlMxAAIwMQ\=\=%23
    #  {"nodeid":"3ec97127-da8b-4ba3-ad1c-5e479c48eba6","filename":"example.pdf","callback":nil}%

    handler_id = ''

    urldochndlr = ''
    urldochndlr << DOC_SERVICE_URL
    urldochndlr << 'documents/'
    urldochndlr << internal_file_name
    urldochndlr << '/node-id?token='
    urldochndlr << URI::encode(pass_in_token)

    LOG.debug("url for document node retrieve: " + urldochndlr)

    resp = generate_http_request(urldochndlr, "", "", "GET")

    response_code = map_response(resp.code)
    if response_code == HTTP_OK

      #invalid JSON is returned from this request
      resp.body.gsub!(':null', ':""')
      resp.body.gsub!(':nil', ':""')

      parsed = JSON.parse(resp.body)
      LOG.debug(parsed)

      handler_id = parsed["nodeid"].to_s

    else
      api_svc_halt HTTP_BAD_REQUEST, '{"error":"Could not locate uploaded document handler"}'
    end

    ## add required entities to the request
    request_body['document']['patient_id'] = patientid
    request_body['document']['handler'] = handler_id
    request_body['document']['source'] = 1
    request_body['document']['format'] = "PDF"

    LOG.debug(request_body.to_s)

    # http://localservices.carecloud.local:3000/patients/:patient_id/documents/create.json?token=
    urldoccrt = ''
    urldoccrt << API_SVC_URL
    urldoccrt << 'patients/'
    urldoccrt << patientid.to_s
    urldoccrt << '/documents/create.json?token='
    urldoccrt << URI::encode(pass_in_token)

    LOG.debug("url for document create: " + urldoccrt)

    resp = generate_http_request(urldoccrt, "", request_body.to_json, "POST")

    LOG.debug(resp.body)
    response_code = map_response(resp.code)

    if response_code == HTTP_CREATED

      parsed = JSON.parse(resp.body)
      LOG.debug(parsed)

      returned_value = parsed

      body(returned_value.to_s)
    else
      body(resp.body)
    end

    status response_code

  end


  # post uploads-dev.carecloud.local/documents/upload
  # required params:
  #    token:  token
  # optional params:
  #    preview: true (this will tell alfresco to keep the image temporarily)
  # curl -F "RemoteFile=@example.pdf" http://uploads-dev.carecloud.local/documents/upload\?token\=AQIC5wM2LY4SfczPZwSF0MGE2uTaM5NHZwC5vuNytaH7Wsk\=@AAJTSQACMDMAAlNLAAk1NzE0OTMzNTEAAlMxAAIwMQ\=\=%23
  ## CURL document up. build GET request to get Handler. Set handler on request below. World works
  def alfresco_upload (file, token)

    urluplddoc = ''
    urluplddoc << DOC_SERVICE_URL
    urluplddoc << 'documents/upload?token='
    urluplddoc << URI::encode(token)

    LOG.debug("curl -F RemoteFile=@#{file} #{urluplddoc}")
    response = `curl -F RemoteFile=@#{file} #{urluplddoc}`
    ## note: there is no response from this call. This i am told is due to the scanner software were response indicates failure

  end

  def determine_file_type(file)

    LOG.debug("file -Ib #{file}")
    mimetype = `file -Ib #{file}`.gsub(/\n/, "")
    LOG.debug(mimetype)

    return mimetype

  end

end