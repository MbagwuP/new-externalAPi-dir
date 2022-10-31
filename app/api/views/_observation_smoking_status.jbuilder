json.observation do 
	json.smokingStatus do
		json.smokingStatus do
			json.account_number patient.external_id
			json.mrn patient.chart_number
			json.patient_name [contact.first_name,contact.last_name].compact.join(" ")
			json.identifier patient.external_id
			json.status smoking_status.status
			json.category_code "social-history"
			json.category_code_system "observation-category"
			json.category_code_display social_history_code.displayName
			json.code smoking_status.code.code
			json.code_system "loinc"
			json.code_display smoking_status.code.displayName
			json.issue_date smoking_status.start_date
			json.value_system smoking_status.value_code.codeSystemName
			json.value_code smoking_status.value_code.code
			json.value_text smoking_status.title

			json.provider do
			  json.identifier provider.id	
				json.npi provider.npi
				json.last_name provider.last_name
				json.first_name provider.first_name
			end

			json.healthcare_entity do
  			json.partial! :healthcare_entity, healthcare_entity: business_entity
			end
		end
	end
end
