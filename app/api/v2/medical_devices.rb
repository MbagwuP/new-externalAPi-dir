class ApiService < Sinatra::Base

  get '/v2/medical_devices/:id' do
    medical_device_id = params[:id]
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false
    @summary = params[:_summary] if params[:_summary].present?

    base_path = "implantable_devices/#{medical_device_id}/find_by_id.json"
    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: {},
      rescue_string: "Medical Device"
    )

    @medical_device = resp['implantable_device']

    status HTTP_OK
    jbuilder :show_medical_device
  end

  get '/v2/medical_devices' do
    patient_id = params[:patient_id]
    @include_provenance_target = params[:_revinclude] == 'Provenance:target' ? true : false
    @summary = params[:_summary] if params[:_summary].present?

    validate_patient_id_param(patient_id)

    base_path = "implantable_devices/list_by_patient.json"
    resp = evaluate_current_internal_request_header_and_execute_request(
      base_path: base_path,
      params: { patient_id: patient_id },
      rescue_string: "Medical Devices"
    )
    @medical_devices = resp.map { |e| e['implantable_device'] }

    status HTTP_OK
    jbuilder :list_medical_devices
  end
end
