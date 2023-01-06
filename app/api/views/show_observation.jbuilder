observation = OpenStruct.new(@observation)
patient = OpenStruct.new(observation.patient)
business_entity = OpenStruct.new(observation.business_entity)
provider = OpenStruct.new(observation.provider)

json.observation do 
	json.vitalSigns do
		json.vitalSigns do
			json.account_number patient.external_id
			json.mrn patient.chart_number
			json.patient_name patient.full_name
			json.identifier observation.id.to_s + "-#{@observation_type}"
			json.status 'Final'
			json.category do
				json.child! do 
					json.coding do
						json.child! do
							json.code "vital-signs"
							json.code_system "observation-category"
							json.code_display "vital-signs"
						end
					end
					json.text 'Vital Signs'
				end
			end
			json.code do
				json.coding do
					json.child! do
						json.code observation.code == ObservationCode::WEIGHT ? ObservationCode::BODY_WEIGHT : observation.code
						json.code_system "loinc"
						json.code_display observation.code_display
					end
				end
				json.text observation.code_display
			end
			json.encounter observation.encounter
			json.effective_start_date observation.effective_start_date
			json.value_quantity do
				json.value observation.value
				json.unit get_unit(observation.code, observation.unit_abbreviation)
				json.system 'unitsofmeasure'
				json.code get_unit(observation.code, observation.unit_abbreviation)
			end

			json.provider do
			  json.identifier provider.try(:id)	
				json.npi provider.try(:npi)
				json.last_name provider.try(:last_name)
				json.first_name provider.try(:first_name)
			end

			json.healthcare_entity do
				json.partial! :healthcare_entity, healthcare_entity: business_entity
			end
		end
	end
end