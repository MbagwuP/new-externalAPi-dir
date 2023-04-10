#
# File:       document_service.rb
#
#
# Version:    1.0
require 'securerandom'
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

    LOG.debug("__ENCODING__: #{__ENCODING__}, Encoding.default_external: #{Encoding.default_external}")

    ## parameters passed in
    #LOG.debug(params[:metadata])
    #LOG.debug(params[:payload])

    # See Rack's magic parameter handling
    # http://blog.yetanotherjosh.com/post/33685107221/racks-magic-parameter-handling-explained-and

    # Get metadata params from the request
    begin
       # support passing metadata as json
       # example: curl -F 'metadata={"document":{"name":"test","format":"pdf","description":"test","source":"19"}}'
       request_body = JSON.parse(params[:metadata])
    rescue
       # support passing metadata as key/value pairs (ex. html input form)
       # curl -F 'metadata[document][name]=test' \
       #      -F 'metadata[document][description]=test' \
       #      -F 'metadata[document][format]=pdf' \
       #      -F 'metadata[document][source]=19' \
       request_body = params[:metadata] if params[:metadata].kind_of?(Hash)
       api_svc_halt HTTP_BAD_REQUEST, '{"error":"Failed Parsing Request Body!"}' if request_body.blank?
    end

    validate_param(params[:patientid], PATIENT_REGEX, PATIENT_MAX_LEN)
    patientid = params[:patientid]
    patientid.slice!(/^patient-/) if /^patient-/ =~ patientid 

    # Get access_token
    # access_token can be sent in header (when oauth) or query params (v1, user token).
    pass_in_token = oauth_request? ? escaped_oauth_token : CGI::unescape(params[:authentication] || "")

    # if it's an OAuth token get cbe from session, otherwise call webservices    
    business_entity = oauth_request? ? current_business_entity : get_business_entity(pass_in_token)
    patientid = get_internal_patient_id(patientid, business_entity, pass_in_token)

    if request_body['document'].nil?
      api_svc_halt HTTP_BAD_REQUEST, "{\"error\":\"The document is missing from the POST\"}"
    end

    if request_body['document']['name'].nil?
      api_svc_halt HTTP_BAD_REQUEST, "{\"error\":\"The document.name is missing from the POST\"}"
    end

    if params['payload'].nil?
      api_svc_halt HTTP_BAD_REQUEST, "{\"error\":\"The payload is missing from the POST\"}"
    end

    document_name = request_body['document']['name']
    document_binary = params['payload'][:tempfile]

    # http://stackoverflow.com/questions/51572/determine-file-type-in-ruby
    file_extension = File.extname(document_name)

    LOG.debug("Document file name: #{document_name}, Document file extension: #{file_extension}")

    if file_extension.empty?
      api_svc_halt HTTP_BAD_REQUEST, "{\"error\":\"File name must have an extension. File name: #{document_name}\"}"
    end

    format = file_extension.delete('.').upcase

    LOG.debug("Document format: #{format}")

    valid_formats = ['BMP', 'DOC', 'DOCX', 'GIF', 'JPG', 'JPEG', 'PDF', 'PNG', 'PPT', 'PPTX', 'RTF', 'TIF', 'TIFF', 'XLS', 'XLSX']

    unless valid_formats.include?(format)
      api_svc_halt HTTP_BAD_REQUEST, "{\"error\":\"The #{format} file type is not supported. It must be one of: #{valid_formats.join(',')}\"}"
    end

    begin
      local_file_name = create_local_file_by_name(patientid, document_binary, document_name)

      ## helpful articles
      ##   http://stackoverflow.com/questions/3938569/how-do-i-upload-a-file-with-metadata-using-a-rest-web-service
      ##   http://leejava.wordpress.com/2009/07/30/upload-file-from-rest-in-ruy-on-rail-with-json-format/
      ##
      ## Request test:
      ##   curl -F "metadata=<documenttest2.json" -F "payload=@example.pdf" http://localhost:9292/v1/documents/patient/legacy_patient_id-13525-1/upload\?authentication\=AQIC5wM2LY4Sfcwea7zIYP8QQwMd6vvB8bHXOVDwT8mU73U%3D%40AAJTSQACMDMAAlNLAAstMTM0MDgzNjcwNQACUzEAAjAx%23
      begin
        response = dms_upload(local_file_name, pass_in_token)
      rescue Errno::ECONNREFUSED
        api_svc_halt HTTP_SERVICE_UNAVAILABLE, "upload service is unavailable"
      rescue => e
        LOG.warn "#{e.message}:#{e.http_body}"
        api_svc_halt e.http_code, "#{e.message}:#{e.http_body}"
      end  

      handler_id = response["nodeid"]      

      ## add required entities to the request
      request_body['document']['patient_id'] = patientid
      request_body['document']['handler'] = handler_id
      request_body['document']['source'] = 1 if request_body['document']['source'].blank?
      request_body['document']['format'] = format

      #LOG.debug "Request body "
      #LOG.debug(request_body.to_s)

      response = create_document(patientid, pass_in_token, request_body)
      @resp = JSON.parse(response)
      jbuilder :show_document    
    ensure
      unless local_file_name.nil?
        FileUtils.remove(local_file_name)
      end
    end
  end

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

  post '/v1/documents/patient/:patientid/batch_upload?' do

    ## parameters passed in
    #LOG.debug(params[:metadata])
    #LOG.debug(params[:payload])
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
    # Validate the input parameters
    pdf_array_of_data = Array.new
    errors = []
    success = []

    if params[:metadata].length == params[:payload].length

      payload_queue = params[:payload].map{|pq| pq}
      if params[:metadata][0].is_a?(String)
      meta_data_queue = params[:metadata].map{|mq| JSON.parse(mq)}
      (0..payload_queue.length-1).each do |i|
        pdf_array_of_data << {"payload" => payload_queue[i], "meta_data" => meta_data_queue[i]}
      end

      else
        (0..payload_queue.length-1).each do |i|
          pdf_array_of_data << {"payload" => payload_queue[i], "meta_data" => params[:metadata]["#{i}"]}
        end
      end

      pdf_array_of_data.each do |payload|
        local_file = create_local_file(patientid, payload)
        file_type = File.extname(local_file)
        # http://stackoverflow.com/questions/51572/determine-file-type-in-ruby
        document_type_regex = File.extname(local_file)
        file_type_name = ''
        if document_type_regex == '.jpg'
          document_type_regex = '.jpg'
          file_type_name = "JPG"
        elsif document_type_regex == '.jpeg'
          document_type_regex = '.jpeg'
          file_type_name = "JPEG"
        else
          document_type_regex = '.pdf'
          file_type_name = "PDF"
        end
        if file_type.match(document_type_regex) == nil
          errors << {:pdf_name =>  payload['meta_data']['document']['name'] }
          FileUtils.remove(local_file)
        else
          response = dms_upload(local_file, pass_in_token)
          handler_id = response["nodeid"]
          ## use rest client to do multipart form upload
          FileUtils.remove(local_file)
          ## add required entities to the request
          payload['meta_data']['document']['patient_id'] = patientid
          payload['meta_data']['document']['handler'] = handler_id
          payload['meta_data']['document']['source'] = 1 if payload['meta_data']['document']['source'].blank?
          payload['meta_data']['document']['format'] = file_type_name
          create = create_document(patientid, pass_in_token, payload['meta_data'])
          if create == 201
            success << {:pdf_name =>  payload['meta_data']['document']['name'] }
          else
            errors << {:pdf_name =>  payload['meta_data']['document']['name'] }
          end
        end
      end
    else
      api_svc_halt HTTP_BAD_REQUEST, '{"A mismatch of payload/metadata detected"}'
    end
    the_response_hash = {:patient_id => params[:patientid].to_s, :errors => errors, :success => success}
    body(the_response_hash.to_json)
    HTTP_CREATED

  end


  # --------------------------
  # Params definition
  # :id     - Can accept a legacy_patient_id or a Chart id 
  #       (e.x.: a1133a)
  # 
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
  #  curl -F "metadata=<documenttest.json" -F "payload=@example.pdf" http://localhost:9292/v1/documents/patient/legacy/a133a/upload\?authentication\=
  # server action: Return status of upload
  # server response:
  # --> if document successfully uploaded: 201, with document id in response data
  # --> if not authorized: 401
  # --> if patient not found: 404
  # --> if bad request: 400

  #Upload Document by Patient MRN

  post '/v1/documents/patient/legacy/:id/upload?' do

    ## parameters passed in
    #LOG.debug(params[:metadata])
    #LOG.debug(params[:payload])
    # Validate the input parameters
    request_body = JSON.parse(params[:metadata])
    #change to validate legacy length
    #validate_param(params[:patientid], PATIENT_REGEX, PATIENT_MAX_LEN)
    id = params[:id].to_s
    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])

    ## muck with the request based on what internal needs
    business_entity = get_business_entity(pass_in_token)

    ## if external id, lookup internal
    patientid = get_patient_id_with_other_id(id, business_entity, pass_in_token)

    local_file = create_local_file(patientid, params)

    # http://stackoverflow.com/questions/51572/determine-file-type-in-ruby
    file_type = File.extname(local_file)

    document_type_regex = File.extname(local_file)

    if document_type_regex == '.jpg'
      document_type_regex = '.jpg'
      file_type_name = "JPG"
    else
      document_type_regex = '.pdf'
      file_type_name = "PDF"
    end

    #application/pdf; charset=binary
    api_svc_halt HTTP_BAD_REQUEST, '{"error":"Document must be of type PDF or JPG "}' if file_type.match(document_type_regex) == nil

    ## helpful articles
    ##   http://stackoverflow.com/questions/3938569/how-do-i-upload-a-file-with-metadata-using-a-rest-web-service
    ##   http://leejava.wordpress.com/2009/07/30/upload-file-from-rest-in-ruy-on-rail-with-json-format/
    ##
    ## Request test:
    ##   curl -F "metadata=<documenttest2.json" -F "payload=@example.pdf" http://localhost:9292/v1/documents/patient/legacy_patient_id-13525-1/upload\?authentication\=AQIC5wM2LY4Sfcwea7zIYP8QQwMd6vvB8bHXOVDwT8mU73U%3D%40AAJTSQACMDMAAlNLAAstMTM0MDgzNjcwNQACUzEAAjAx%23
    begin
      response = dms_upload(local_file, pass_in_token)
    rescue Errno::ECONNREFUSED
      api_svc_halt HTTP_SERVICE_UNAVAILABLE, "upload service is unavailable"
    rescue => e
      LOG.warn "#{e.message}:#{e.http_body}"
      api_svc_halt e.http_code, "#{e.message}:#{e.http_body}"
    end  

    handler_id = response["nodeid"]

    ## use rest client to do multipart form upload
    FileUtils.remove(local_file)

    ## add required entities to the request
    request_body['document']['patient_id'] = patientid
    request_body['document']['handler'] = handler_id
    request_body['document']['source'] = 1 if request_body['document']['source'].blank?
    request_body['document']['format'] = file_type_name

    #LOG.debug "Request body "
    #LOG.debug(request_body.to_s)

    create_document(patientid, pass_in_token, request_body)
  end

  # --------------------------
  # Params definition
  # Patient_ID

  # server action: Return List of uploaded Document Ids
  # server response:
  # --> if document successfully found
  # --> if not authorized: 401
  # --> if patient not found: 404
  # --> if bad request: 400

  #list of document_ids for patient

  get '/v1/document/listbypatient/:patient_id' do
    validate_param(params[:patient_id], PATIENT_REGEX, PATIENT_MAX_LEN)
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)
    patientid = params[:patient_id]
    patientid.slice!(/^patient-/)
    patient_id = get_internal_patient_id(patientid, business_entity, pass_in_token)

    urldocument = ''
    urldocument << API_SVC_URL
    urldocument << '/patients/'
    urldocument << patient_id
    urldocument << '/documents/getdocuments'
    urldocument << '.json?token='
    urldocument << CGI::escape(pass_in_token)

    begin
      response = RestClient.get(urldocument)
    rescue => e
      begin
        errmsg = "Retrieving Document Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    parsed = JSON.parse(response.body)
    documents = []
    parsed.each do |array|
      p = array['document']
      scrub = {}
      scrub['doc_id'] = p['document_handler']
      scrub['format_type'] = p['document_format']
      scrub['name'] = p['name']
      scrub['description'] = p['description']
      scrub['created_at'] = p['created_at']
      documents << scrub
    end
    body(documents.to_json)
    status HTTP_OK

  end


  # --------------------------
  # Params definition
  # Doc_id
  # Patient_id

  # server action: Return List of uploaded Document Ids
  # server response:
  # --> if document successfully found
  # --> if not authorized: 401
  # --> if patient not found: 404
  # --> if bad request: 400

  #Get a document

  get '/v1/getdocument/:patient_id/:doc_id' do
    validate_param(params[:patient_id], PATIENT_REGEX, PATIENT_MAX_LEN)
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)
    patientid = params[:patient_id]
    patientid.slice!(/^patient-/)

    pdf = ''
    pdf << DOC_SERVICE_URL
    pdf << '/documents/'
    pdf << params[:doc_id]
    pdf << '/pdf?token='
    pdf << CGI::escape(pass_in_token)

    puts pdf

    begin
      pdf = RestClient.get(pdf)
    rescue => e
      begin
        errmsg = "Document Creation Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    content_type 'application/pdf'
    pdf.to_str
   end

  get '/v1/documentsources' do
    pass_in_token = oauth_request? ? escaped_oauth_token : CGI::unescape(params[:authentication] || "")
    business_entity = oauth_request? ? current_business_entity : get_business_entity(pass_in_token)
    document_source = "#{API_SVC_URL}businesses/#{business_entity}/document_sources.json?token=#{CGI::escape(pass_in_token)}"
    begin
      response = RestClient.get(document_source)
    rescue => e
      begin
        errmsg = "Document Source Look Up Failed. #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end
    body(response.body)
    status HTTP_OK
  end


  def create_local_file(patientid, params)
    document_binary = params['payload'][:tempfile]
    document_name = params['payload'][:filename]

    return create_local_file_by_name(patientid, document_binary, document_name)
  end

  def create_local_file_by_name(patientid, document_binary, document_name)
    #rewind this file
    document_binary.rewind

    file_extension = File.extname(document_name)

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
    internal_file_name << SecureRandom.uuid
    internal_file_name << file_extension

    # Handle Content-Transfer-Encoding scheme
    ##  https://tools.ietf.org/html/rfc2045#section-6
    ##  transfer encodings: http://www.iana.org/assignments/transfer-encodings/transfer-encodings.xhtml
    encoding = request.env['HTTP_CONTENT_TRANSFER_ENCODING']
    # Note: for backwards compatability, when no encoding is specified we need to treat the file as 'base64' encoded.
    ##   v2 of our documents api should do away with this and default to 'binary' which is a more sensible expectation.  
    ##   Any clients that wish to encode their docs in base64 should specify this in the 
    ##   Content-Transfer-Encoding header so we can decode accordingly.
    base64_encoded = encoding.nil? || (encoding == 'base64')
    File.open(internal_file_name, "wb") do |file|
      file.write(base64_encoded ? Base64.decode64(document_binary.read) : document_binary.read)
    end
    return internal_file_name
  end

  def create_document(patientid, pass_in_token, request_body)
    urldoccrt = ''
    urldoccrt << API_SVC_URL
    urldoccrt << 'patients/'
    urldoccrt << patientid.to_s
    urldoccrt << '/documents/create.json?token='
    urldoccrt << CGI::escape(pass_in_token)

    begin
      LOG.debug("Posting document to webservices. URL: #{urldoccrt}, Body: #{request_body.to_json}")

      response = RestClient.post(urldoccrt, request_body.to_json, :content_type => :json)

      LOG.debug "Posted document to webservices response: #{response.inspect}"
    rescue => e
      begin
        errmsg = "Document Creation Failed - #{e.message}"
        api_svc_halt e.http_code, errmsg
      rescue
        api_svc_halt HTTP_INTERNAL_ERROR, errmsg
      end
    end

    response
  end

  ## upload the document to the DMS server
  def dms_upload (file_path, token, params = {})
    LOG.debug "Dms::DocumentAPI uploading file: #{file_path}, params: #{file_path}"

    file = File.new(file_path, 'rb')
    options = params.merge(file: file, token: token)

    res = JSON.parse(post("#{DOC_SERVICE_URL}/documents",options))

    LOG.debug "Dms::DocumentAPI upload response: #{res.inspect}"

    return res
  end


end