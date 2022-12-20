class ApiService < Sinatra::Base

  get '/v2/diagnostic_reports/:id' do
    params_1=params[:id]
    base_path = "labs/get_results_by_patient_and_code.json"
    parameters = { id: params_1 }
    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: parameters,
      rescue_string: "Diagnostic report "
    )


    base_path = "documents/#{params_1}.json"

    resp_doc = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: { id: params_1 },
      rescue_string: "Document reference "
    )
    @document = resp_doc['document']
    doc_url=@document["document_url"]
    @api_key=APP_API_KEY

    begin
      internal_signed_request = sign_internal_request(url: doc_url, method: :get, headers: {accept: :json})
      @data = internal_signed_request.execute
    rescue => e
      @data=nil
    end

    @lab_result = resp["lab_results"]
    @patient = OpenStruct.new resp["patient"]["patient"]
    @provider = OpenStruct.new resp["provider"]["provider"]
    @business_entity = OpenStruct.new resp["business_entity"]["business_entity"]
    base_path1 = "patient_summary/generate_json_by_patient_id_and_component.json"

    resp1 = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path1,
      params: { patient_id: @patient.external_id, ccd_components: ['labresults'], code: params[:code], category: params[:category],date: params[:date]},
      rescue_string: "Diagnostic report "
    )
    patient_summary = resp1['patient_summary']
    @encounter = resp1['encounter']['encounter']
    patient_summary = JSON.parse(patient_summary) if patient_summary
    diagnostic_reports_section = patient_summary['ClinicalDocument']['component']['structuredBody']['component']['section']


    @diagnostic_report = ResultSection.new(diagnostic_reports_section)

    @code = "5778-6"

    @include_code_target = params[:code] || nil
    @include_category_target = params[:category] || nil
    @include_date_target = params[:date] || nil
    status HTTP_OK
    jbuilder :list_diagnostic_reports_id

  end
  get '/v2/diagnostic_reports' do
    patient_id = params[:patient_id]
    
    validate_patient_id_param(patient_id)

    base_path = "patient_summary/generate_json_by_patient_id_and_component.json"
    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: { patient_id: patient_id, ccd_components: ['labresults'], code: params[:code], category: params[:category], date: params[:date], get_document: true},
      rescue_string: "Diagnostic report "
    )

    @include_code_target = params[:code] || nil
    @include_category_target = params[:category] || nil
    @include_date_target = params[:date] || nil
    patient_summary = resp['patient_summary']

    patient_summary = JSON.parse(patient_summary) if patient_summary
    diagnostic_reports_section = patient_summary['ClinicalDocument']['component']['structuredBody']['component']['section']

    @diagnostic_report = ResultSection.new(diagnostic_reports_section)
    @patient = resp['patient']['patient']
    @lab_results = resp['lab_results']
    binding.pry
    @lab_results = @include_category_target ? @lab_results.select { |lab_result| (lab_result['lab_request_test']['loinc'] || 'LAB') == @include_category_target } : @lab_results
    # @lab_results = (@include_code_target && @diagnostic_report.code.code == @include_code_target) : @lab_results : @lab_results
    @lab_results = @include_date_target ? @lab_results.select { |lab_result| fhir_date_compare(lab_result['lab_request_test']['ordered_at'], @include_date_target) } : @lab_results
    # if ((@include_code_target == @diagnostic_report.code.code || @include_code_target == nil) &&
    # (@include_category_target == default_category_code || @include_category_target == nil) &&
    # (@include_date_target == test_date || @include_date_target == nil))

    @business_entity = resp['business_entity']['business_entity']
    @encounter = resp['encounter']['encounter']
    @provider = resp['provider']['provider']
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false

    document_hash = resp['document']
    document_url = document_hash['document_url']

    if document_url
      # lab_id=@lab_results[0]['lab_request_test']['id']
      # base_path = "documents/#{lab_id}.json"
      # resp_doc = evaluate_current_internal_request_header_and_execute_request(
      #   base_path: base_path,
      #   params: { id: lab_id },
      #   rescue_string: "Document reference "
      # )
      # @document = resp_doc['document']
      # doc_url=@document["document_url"]
      # @api_key=APP_API_KEY

      # begin
      binding.pry
        internal_signed_request = sign_internal_request(url: document_url, method: :get, headers: {accept: :json})
        @data = internal_signed_request.execute
      # rescue => e
        # @data=nil
      # end
    else
      @data=nil
    end
    status HTTP_OK
    jbuilder :list_diagnostic_reports
  end
end
