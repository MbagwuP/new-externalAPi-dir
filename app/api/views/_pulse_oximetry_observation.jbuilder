patient = observation.patient
business_entity = observation.business_entity
provider = observation.provider
oxygen_saturation = observation.oxygen_saturation
inhaled_oxygen_concentration = observation.inhaled_oxygen_concentration

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
					json.child! do
						json.code ObservationCode::OXYGEN_SATURATION_BY_PULSE_OXIMETRY
						json.code_system "loinc"
						json.code_display observation.code_display_oximetry
					end
				end
				json.text observation.code_display
			end
			json.encounter observation.encounter
			json.effective_start_date observation.effective_start_date

			json.value_quantity do
				json.value oxygen_saturation.value
				json.unit oxygen_saturation.unit
				json.system 'unitsofmeasure'
				json.code "%"
			end
			
			json.component do
				json.child! do
					json.code do
						json.coding do
							json.child! do
								json.code ObservationCode::INHALED_OXYGEN_FLOW_RATE
								json.code_system "loinc"
								json.code_display 'Inhaled oxygen flow rate'
							end
						end
						json.text 'Inhaled oxygen flow rate'
					end
					json.value_quantity do
						json.value '6'
						json.unit 'L/min'
						json.system nil
						json.code 'L/min'
					end
				end

				json.child! do
					json.code do
						json.coding do
							json.child! do
								json.code inhaled_oxygen_concentration.code
								json.code_system "loinc"
								json.code_display inhaled_oxygen_concentration.code_display
							end
						end
						json.text inhaled_oxygen_concentration.code_display
					end
					json.value_quantity do
						json.value inhaled_oxygen_concentration.value
						json.unit inhaled_oxygen_concentration.unit
						json.system 'unitsofmeasure'
						json.code "%"
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
			json.partial! :_provenance, patient: patient, record: observation, provider: provider, business_entity: business_entity, obj: 'Pulse-Oximetry'
		end
	end
end