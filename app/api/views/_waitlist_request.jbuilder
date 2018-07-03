json.id waitlist_request['id']
json.business_entity_id waitlist_request['business_entity_id']
json.appointment_id waitlist_request['appointment_id']
json.appointment_external_id waitlist_request['appointment']['external_id']
json.priority waitlist_request['priority']
json.created_at waitlist_request['created_at']
json.updated_at waitlist_request['updated_at']
json.appointment_request do
  json.visit_reason_id waitlist_request['appointment_request']['nature_of_visit_id']
  json.show_alert waitlist_request['appointment_request']['show_alert']

  json.calendars(waitlist_request['appointment_request']['calendars'])  do |calendar|
    json.resource_id calendar['resource_id']
    json.location_id calendar['location_id']
  end

  json.weekday do
    json.monday waitlist_request['appointment_request']['monday']
    json.tuesday waitlist_request['appointment_request']['tuesday']
    json.wednesday waitlist_request['appointment_request']['wednesday']
    json.thursday waitlist_request['appointment_request']['thursday']
    json.friday waitlist_request['appointment_request']['friday']
    json.saturday waitlist_request['appointment_request']['saturday']
    json.sunday waitlist_request['appointment_request']['sunday']
  end

  json.part_of_day do
    json.morning waitlist_request['appointment_request']['morning']
    json.afternoon waitlist_request['appointment_request']['afternoon']
  end

  json.appointment do
    json.id waitlist_request['appointment']['id']
    json.external_id waitlist_request['appointment']['external_id']
    json.start_time waitlist_request['appointment']['start_time']
    json.end_time waitlist_request['appointment']['end_time']
    json.nature_of_visit_id waitlist_request['appointment']['nature_of_visit_id']
    json.patient_id waitlist_request['appointment']['patient_appointment_details'][0]['external_id']
    json.first_name waitlist_request['appointment']['patient_appointment_details'][0]['first_name']
    json.middle_initial waitlist_request['appointment']['patient_appointment_details'][0]['middle_initial']
    json.last_name waitlist_request['appointment']['patient_appointment_details'][0]['last_name']
    json.date_of_birth_string waitlist_request['appointment']['patient_appointment_details'][0]['date_of_birth_string']
    json.primary_payer_id waitlist_request['appointment']['patient_appointment_details'][0]['primary_payer_id']
  end
end
