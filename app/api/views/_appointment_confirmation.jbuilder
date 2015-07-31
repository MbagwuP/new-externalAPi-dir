json.appointment_confirmation do
    json.appointment_id @appointment_id
    json.comments @confirmation['appointment_confirmation']['comments']
    json.communication_method communication_methods.invert[@confirmation['appointment_confirmation']['communication_method_id']]
    json.communication_method_description @confirmation['appointment_confirmation']['method_description']
    json.communication_outcome communication_outcomes.invert[@confirmation['appointment_confirmation']['communication_outcome_id']]
    json.created_at @confirmation['appointment_confirmation']['created_at']
    json.date_confirmed @confirmation['appointment_confirmation']['date_confirmed']
    json.id @confirmation['appointment_confirmation']['guid'] || @confirmation['appointment_confirmation']['id']
    json.updated_at @confirmation['appointment_confirmation']['updated_at']
  end