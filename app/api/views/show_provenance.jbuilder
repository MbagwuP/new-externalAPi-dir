if @is_patient
    json.partial! :patient_details_provenance, patient: @resource
else
    json.partial! :_provenance, patient: @patient, record: @resource, 
                provider: @provider, business_entity: @business_entity, obj: @obj
end
