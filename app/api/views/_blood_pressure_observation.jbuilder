patient = observation.patient
business_entity = observation.business_entity
provider = observation.provider
systolic_observation = observation.systolic_observation
diastolic_observation = observation.diastolic_observation

json.observation do 
	json.vitalSigns do
		json.vitalSigns do
			json.account_number patient.external_id
			json.mrn patient.chart_number
			json.patient_name patient.full_name
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
					json.text 'Vital Signs'
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
			
			json.component do
				json.child! do
					json.code do
						json.coding do
							json.child! do
								json.code systolic_observation.code
								json.code_system "loinc"
								json.code_display systolic_observation.code_display
							end
						end
						json.text systolic_observation.code_display
					end
					json.value_quantity do
						json.value systolic_observation.value
						json.unit systolic_observation.unit_abbreviation
						json.system 'unitsofmeasure'
						json.code systolic_observation.unit_abbreviation
					end
				end

				json.child! do
					json.code do
						json.coding do
							json.child! do
								json.code diastolic_observation.code
								json.code_system "loinc"
								json.code_display diastolic_observation.code_display
							end
						end
						json.text diastolic_observation.code_display
					end
					json.value_quantity do
						json.value diastolic_observation.value
						json.unit diastolic_observation.unit_abbreviation
						json.system 'unitsofmeasure'
						json.code diastolic_observation.unit_abbreviation
					end
				end
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

		if include_provenance_target
			json.partial! :_provenance, patient: patient, record: observation, provider: provider, business_entity: business_entity, obj: 'Blood-pressure'
		end
	end
end