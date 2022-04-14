json.id appointment['external_id']

json.appointment_status do
  json.id appointment['appointment_status_id']
  json.code appointment['appointment_status_code']
  json.name appointment['appointment_status_name']
end

json.patient do
  json.id appointment['patient_external_id']
  json.chart_number appointment['chart_number']
  json.date_of_birth appointment['date_of_birth']
  json.first_name appointment['first_name']
  json.last_name appointment['last_name']
  json.middle_initial appointment['middle_initial']
  json.gender_id appointment['gender_id']
  json.email appointment['email']
  json.patient_status appointment['patient_status']
  json.primary_phone_number appointment['primary_phone_number']
end

json.location do
  json.id appointment['location_id']
  json.name appointment['location_name']
end

json.cancellation_details do
  json.id appointment['appointment_cancellation_reason_id']
  json.detail appointment['cancellation_details']
  json.comments appointment['cancellation_comments']
end

json.chief_complaint appointment['reason_for_visit']
json.task_id appointment['task_id']
json.updated_by_application appointment['updated_by_application']
json.appointment_cancellation_reason_id appointment['appointment_cancellation_reason_id']
json.arrived_at appointment['arrived_at']
json.comments appointment['comments']
json.confirmation_details appointment['confirmation_details']
json.departed_at appointment['departed_at']
json.exam_room_id appointment['exam_room_id']
json.is_confirmed appointment['is_confirmed']
json.is_force_overbook appointment['is_force_overbook']

json.patient_contacted appointment['patient_contacted']
json.recurrence_id appointment['recurrence_id']
json.recurrence_index appointment['recurrence_index']
json.referring_physician_npi appointment['referring_physician_npi']

json.visit_reason_id appointment['nature_of_visit_id']
json.resource_id appointment['resource_id']
json.provider_id appointment['provider_id']
json.start_time appointment['start_time']
json.end_time appointment['end_time']
json.created_at appointment['created_at']
json.updated_at appointment['updated_at']

# NOTE: the structure of this response change if it's made by internal service with internal auth token.
if defined?(@internal_request) && @internal_request
  json.nature_of_visit do
    json.id appointment['nature_of_visit_id']
    json.name appointment['nature_of_visit_name']
  end
  json.business_entity do
    json.id appointment['business_entity_id']
    json.name appointment['business_entity_name']
  end
  json.attending_provider do
    json.id appointment['provider_id']
    json.npi appointment['provider_npi']
    json.first_name appointment['provider_first_name']
    json.last_name appointment['provider_last_name']
  end
else
  json.business_entity_id appointment['business_entity_id']
end
