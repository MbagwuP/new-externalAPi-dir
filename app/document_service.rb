#
# File:       document_service.rb
#
#
# Version:    1.0


class ApiService < Sinatra::Base

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
    pass_in_token = CGI::unescape(params[:authentication])

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

    LOG.debug "internal file name"
    LOG.debug(internal_file_name)
    File.open(internal_file_name, "wb") do |file|
      file.write(document_binary.read)
    end

    # http://stackoverflow.com/questions/51572/determine-file-type-in-ruby
    file_type = determine_file_type(internal_file_name)

    document_type_regex = File.extname(internal_file_name)
    if document_type_regex == '.jpg'
        document_type_regex = '\Aimage/\jpeg'
        file_type_name = "JPG"
    else
        document_type_regex = '\Aapplication/\pdf'
        file_type_name = "PDF"
    end

    #application/pdf; charset=binary
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Document must be of type PDF or JPG "}' if file_type.match(document_type_regex) == nil

    ## helpful articles
    ##   http://stackoverflow.com/questions/3938569/how-do-i-upload-a-file-with-metadata-using-a-rest-web-service
    ##   http://leejava.wordpress.com/2009/07/30/upload-file-from-rest-in-ruy-on-rail-with-json-format/
    ##
    ## Request test:
    ##   curl -F "metadata=<documenttest2.json" -F "payload=@example.pdf" http://localhost:9292/v1/documents/patient/patient-1819622/upload\?authentication\=AQIC5wM2LY4SfcxmRf7LAteRndBUo5Qb0z93O%2F0c2CNSJd8%3D%40AAJTSQACMDMAAlNLAAk0MzgzNDA4ODQAAlMxAAIwMQ%3D%3D%23
    response = dms_upload(internal_file_name, pass_in_token)

    handler_id = response["nodeid"]

    ## use rest client to do multipart form upload
    FileUtils.remove(internal_file_name)

    ## add required entities to the request
    request_body['document']['patient_id'] = patientid
    request_body['document']['handler'] = handler_id
    request_body['document']['source'] = 1
    request_body['document']['format'] = file_type_name

    LOG.debug "Request body "
    LOG.debug(request_body.to_s)

    # http://localservices.carecloud.local:3000/patients/:patient_id/documents/create.json?token=
    urldoccrt = ''
    urldoccrt << API_SVC_URL
    urldoccrt << 'patients/'
    urldoccrt << patientid.to_s
    urldoccrt << '/documents/create.json?token='
    urldoccrt << CGI::escape(pass_in_token)

    LOG.debug("url for document create: " + urldoccrt)

    resp = generate_http_request(urldoccrt, "", request_body.to_json, "POST")
    
    LOG.debug(resp.body)
    response_code = map_response(resp.code)

    if response_code == HTTP_CREATED

      parsed = JSON.parse(resp.body)
       LOG.debug "Parsed "
      LOG.debug(parsed)

      returned_value = parsed

      body(returned_value.to_s)
    else
      body(resp.body)
    end

    status response_code

  end

  ## upload the document to the DMS server
  def dms_upload (file_path, token, params = {})
    file = File.new(file_path, 'rb')
    options = params.merge(file: file, token: token)
    res = JSON.parse(post(DOC_SERVICE_URL,options))
    LOG.debug "Dms::DocumentAPI upload response: #{res.inspect}"
    return res
  end

  def determine_file_type(file)

    LOG.debug("file -Ib #{file}")
    mimetype = `file -Ib #{file}`.gsub(/\n/, "")
    LOG.debug "The MIME TYPE"
    LOG.debug(mimetype)

    return mimetype

  end

end