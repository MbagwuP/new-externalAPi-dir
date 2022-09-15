json.observation do 
	json.smokingStatus do
		json.smokingStatus do
			json.partial! :patient, patient: patient
			json.status smoking_status.status
			json.category_code social_history_code.code
			json.category_code_system social_history_code.codeSystem
			json.category_code_display social_history_code.displayName
			json.code_system smoking_status.code.codeSystem
			json.code smoking_status.code.code
			json.code_display smoking_status.code.displayName
			json.issue_date smoking_status.start_date
			json.value_text smoking_status.title
			json.value_code smoking_status.value_code.code
			json.value_system smoking_status.value_code.codeSystemName

			json.provider do
			  json.partial! :provider_extra_light, provider: provider
			end

			json.business_entity do
  			json.partial! :business_entity, business_entity: business_entity
			end
		end
	end
end
