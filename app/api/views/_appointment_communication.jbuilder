json.appointment_id @appointment_id
json.comments @apt_communication['appointment_confirmation']['comments']
json.communication_method communication_methods.invert[@apt_communication['appointment_confirmation']['communication_method_id']]
json.communication_method_description @apt_communication['appointment_confirmation']['method_description']
json.communication_outcome communication_outcomes.invert[@apt_communication['appointment_confirmation']['communication_outcome_id']]
json.created_at @apt_communication['appointment_confirmation']['created_at']
json.id @apt_communication['appointment_confirmation']['guid'] || @apt_communication['appointment_confirmation']['id']
json.updated_at @apt_communication['appointment_confirmation']['updated_at']
