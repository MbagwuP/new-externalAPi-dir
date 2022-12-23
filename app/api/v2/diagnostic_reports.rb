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

    document = resp["lab_results"]["lab_request_test"]["document"] 
    doc_url = document ? document["document_url"] : nil  

    if doc_url
      begin
        internal_signed_request = sign_internal_request(url: doc_url, method: :get, headers: {accept: :json})
        @data = internal_signed_request.execute
      rescue => e
        @data=nil
      end
    else
      @data = nil
    end

    @lab_result = resp["lab_results"]
    if !@lab_result.empty?

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
    end

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
    @patient = resp['patient'] ? resp['patient']['patient'] : nil
    @lab_requests = resp['lab_requests']
    @lab_requests = @include_category_target ? @lab_requests.select { |lab_request| (lab_request['lab_request_test']['loinc'] || 'LAB') == @include_category_target } : @lab_requests
    # @lab_results = (@include_code_target && @diagnostic_report.code.code == @include_code_target) : @lab_results : @lab_results
    @lab_requests = @include_date_target ? @lab_requests.select { |lab_request| fhir_date_compare(lab_request['lab_request_test']['ordered_at'], @include_date_target) } : @lab_requests
    # if ((@include_code_target == @diagnostic_report.code.code || @include_code_target == nil) &&
    # (@include_category_target == default_category_code || @include_category_target == nil) &&
    # (@include_date_target == test_date || @include_date_target == nil))

    if !@lab_requests.empty?
      @business_entity = resp['business_entity'] ? resp['business_entity']['business_entity'] : nil
      @encounter = resp['encounter'] ? resp['encounter']['encounter'] : nil
      @provider = resp['provider'] ? resp['provider']['provider'] : nil
      @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false

      @lab_requests.each do |lab_request|
        document_hash = lab_request['lab_request_test']['document']
        document_url = document_hash ? document_hash['document_url'] : nil
        if document_url
          begin
            internal_signed_request = sign_internal_request(url: document_url, method: :get, headers: {accept: :json})
            data = internal_signed_request.execute
          rescue => e
            data=nil
          end
        else
          data=nil
        end
        lab_request['lab_request_test']['data'] = data
      end
    end

    status HTTP_OK
    jbuilder :list_diagnostic_reports
  end
end
