lab_result = OpenStruct.new(lab_result)
patient = OpenStruct.new(lab_result.patient)
business_entity = OpenStruct.new(lab_result.business_entity)
provider = OpenStruct.new(lab_result.provider)

json.observation do 
	json.labResult do
		json.labResult do
			json.partial! :patient, patient: patient
			json.identifier lab_result.id
			json.text lab_result.text
			json.text_status 'generated'
			json.result_status 'final'
			json.lab_test_code lab_result.lab_test_code
			json.lab_test_code_system lab_result.lab_test_code_system
			json.lab_test_code_display lab_result.text
			json.lab_test_code_text lab_result.text
			json.effective_period_start lab_result.measured_at
			json.effective_period_end nil
			json.result_value do
				json.value lab_result.result_value
				json.value_code nil
        json.value_code_system nil
        json.value_unit nil
			end
			json.reference_range_low do
				json.value lab_result.reference_lower_bound
				json.value_code nil
        json.value_code_system nil
        json.value_unit nil
			end
			json.reference_range_high do
				json.value lab_result.reference_upper_bound
				json.value_code nil
        json.value_code_system nil
        json.value_unit nil
			end

			json.provider do
				json.partial! :provider_extra_light, provider: provider
			end

			json.business_entity do
				json.partial! :business_entity, business_entity: business_entity
			end
		end
	end
end