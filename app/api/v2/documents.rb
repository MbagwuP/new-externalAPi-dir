class ApiService < Sinatra::Base

  TYPES = {
    "Progress note" => "11506-3",
    "Procedure Note" => "28570-0",
    "History and Physical" => "34117-2",
    "DISCHARGE SUMMARY" => "18842-5",
    "CONSULTS NOTE" => "11488-4" 
  }

  get '/v2/document/:id' do
    doc_id = params[:id]
    base_path = "documents/#{doc_id}.json"

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: { id: doc_id },
      rescue_string: "Document reference "
    )
    @document = resp['document']
    @api_key = APP_API_KEY
    keys = TYPES.keys
    target = @document["document_source_name"].upcase
    keys=keys.select{|k| target.start_with? k.upcase}
    @type = TYPES[keys[0]] || "11502-2"
    url = @document["document_url"]
    internal_signed_request = sign_internal_request(url: url, method: :get, headers: {accept: :json})
    @doc = internal_signed_request.execute
    status HTTP_OK
    jbuilder :document_reference
  end

  get '/v2/documents' do
    @api_key = APP_API_KEY
    if params[:id]
      base_path = "documents/#{params[:id]}.json"

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: { id: params[:id] },
      rescue_string: "Document reference "
    )
    @documents = [resp['document']]
    else
      patient_id = params[:patient_id]
      validate_patient_id_param(patient_id)

      base_path = "patients/#{patient_id}/documents/list_by_patient_id.json"

      resp = evaluate_current_internal_request_header_and_execute_request(
        base_path: base_path,
        params: { patient_id: patient_id, date: params[:date] },
        rescue_string: "Document reference "
      )

      @documents = resp['documents']
    end
    @is_provenance_target_present = params[:_revinclude] == 'Provenance:target' ? true : false
    @category = params[:category] || "clinical-note"
    @keys = TYPES.keys
    @documents = @documents.each do |doc|
        target = doc["document_source_name"].upcase
        keys=@keys.select{|k| target.start_with? k.upcase}
        doc["type"] = TYPES[keys[0]] || "11502-2"
        url = doc["document_url"]
        internal_signed_request = sign_internal_request(url: url, method: :get, headers: {accept: :json})
        doc["content_data"] = internal_signed_request.execute
      end
    @documents = @documents.select{|doc| doc["type"] == params[:type]} if params[:type].present?
    if params[:_summary] == "count"
      @count_summary =  @documents.entries.length
    end
    status HTTP_OK
    jbuilder :list_document_reference
  end
end
