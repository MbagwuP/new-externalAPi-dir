class ApiService < Sinatra::Base

  get '/v2/documents' do
    patient_id = params[:patient_id]
    validate_patient_id_param(patient_id)

    base_path = "patients/#{patient_id}/documents/list_by_patient_id.json"

    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: { patient_id: patient_id },
      rescue_string: "Document reference "
    )

    @documents = resp['documents']

    status HTTP_OK
    jbuilder :list_document_reference
  end
end
