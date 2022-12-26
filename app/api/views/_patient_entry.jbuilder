json.patient_list do
	json.patient_identifier patient.external_id
	json.first_name patient.first_name
	json.last_name patient.last_name
	json.date_of_birth patient.dob
end