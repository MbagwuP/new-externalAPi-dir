observation = OpenStruct.new(observation)
patient = OpenStruct.new(observation.patient)
business_entity = OpenStruct.new(observation.business_entity)
provider = OpenStruct.new(observation.provider)

json.observation do 
	json.vitalSigns do
		json.vitalSigns do
			json.partial! :patient, patient: patient
			json.identifier observation.id
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
				end
			end
			json.code do
				json.coding do
					json.child! do
						json.code observation.code
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
				json.unit observation.unit
				json.system 'unitsofmeasure'
				json.code observation.code
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