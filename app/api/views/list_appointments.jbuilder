json.array! @resp do |appt|
  json.appointment do

    json.id appt['appointment']['external_id']

    json.appointment_status do
      json.id appt['appointment']['appointment_status_id']
      json.code appt['appointment']['appointment_status_code']
      json.name appt['appointment']['appointment_status_name']
    end

    json.patient do
      json.id appt['appointment']['patient_external_id']
      json.chart_number appt['appointment']['chart_number']
      json.date_of_birth appt['appointment']['date_of_birth']
      json.first_name appt['appointment']['first_name']
      json.last_name appt['appointment']['last_name']
      json.middle_initial appt['appointment']['middle_initial']
      json.gender_id appt['appointment']['gender_id']
      json.email appt['appointment']['email']
      json.patient_status appt['appointment']['patient_status']
      json.primary_phone_number appt['appointment']['primary_phone_number']
    end

    json.location do
      json.id appt['appointment']['location_id']
      json.name appt['appointment']['location_name']
    end

    json.last_eligibility_outcome do
      json.id appt['appointment']['last_eligibility_outcome_id']
      json.code appt['appointment']['last_eligibility_outcome_code']
      json.message appt['appointment']['last_eligibility_outcome_message']
    end

    json.cancellation_details do
      json.id appt['appointment']['appointment_cancellation_reason_id']
      json.detail appt['appointment']['cancellation_details']
      json.comments appt['appointment']['cancellation_comments']
    end

    json.chief_complaint appt['appointment']['reason_for_visit']
    json.appointment_cancellation_reason_id appt['appointment']['appointment_cancellation_reason_id']
    json.arrived_at appt['appointment']['arrived_at']
    json.business_entity_id appt['appointment']['business_entity_id']
    json.comments appt['appointment']['comments']
    json.confirmation_details appt['appointment']['confirmation_details']
    json.departed_at appt['appointment']['departed_at']
    json.exam_room_id appt['appointment']['exam_room_id']
    json.is_confirmed appt['appointment']['is_confirmed']
    json.is_force_overbook appt['appointment']['is_force_overbook']

    json.patient_contacted appt['appointment']['patient_contacted']
    json.recurrence_id appt['appointment']['recurrence_id']
    json.recurrence_index appt['appointment']['recurrence_index']
    json.referring_physician_name appt['appointment']['referring_physician_name']

    json.visit_reason_id appt['appointment']['nature_of_visit_id']
    json.resource_id appt['appointment']['resource_id']
    json.provider_id appt['appointment']['provider_id']
    json.start_time appt['appointment']['start_time']
    json.end_time appt['appointment']['end_time']
    json.created_at appt['appointment']['created_at']
    json.updated_at appt['appointment']['updated_at']

  end
end
