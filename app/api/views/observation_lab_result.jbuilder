lab_result = OpenStruct.new @lab_result
json.observation do 
    json.labResult do
        json.labResult do
            json.account_number @patient.external_id
			json.mrn @patient.chart_number
			json.patient_name @patient.full_name
			json.external_id @patient.external_id
            json.identifier "#{lab_result.id}-#{ObservationType::LAB_REQUEST}"
			json.text lab_result.lab_request_test_description
			json.text_status 'generated'
			json.result_status 'final'
			json.lab_test_code @code
			json.lab_test_code_system lab_result.lab_test_code_system
			json.lab_test_code_display lab_result.lab_request_test_description
			json.lab_test_code_text lab_result.text
			json.effective_period_start lab_result.ordered_at
			json.effective_period_end nil
			json.result_value do
				json.value lab_result.lab_request_test_description
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
				json.partial! :provider_extra_light, provider: @provider
			end

			json.business_entity do
				json.partial! :business_entity, business_entity: @business_entity
			end


        end
    end
end