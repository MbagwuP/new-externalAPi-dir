json.provenance do

	json.identifier "patient-provenance-#{patient.external_id}"
	json.text do
		json.status 'generated'
		json.div ''
	end
	json.target do
		json.child! do
			json.identifier patient.external_id
			json.name 'Patient'
		end
	end
	json.occurred_period do
		json.start nil
		json.end nil
	end

	json.recorded_date patient.created_at
	json.location do
		json.identifier nil
		json.name nil
	end

	json.reason do
		json.child! do
			json.code nil
			json.code_system nil
		end
	end

	json.agent do
		json.child! do
			json.type_coding do
				json.code "author"
        json.code_system "http://terminology.hl7.org/CodeSystem/provenance-participant-type"
        json.code_display "Author"
			end
			json.who do
				json.identifier patient.primary_provider_id
				json.name 'Practitioner'
			end
			json.on_behalf_of do
				json.identifier patient.business_entity_id
				json.name 'Organization'
			end
		end

		json.child! do
			json.type_coding do
				json.code "transmitter"
        json.code_system "http://terminology.hl7.org/CodeSystem/provenance-participant-type"
        json.code_display "Transmitter"
			end
			json.who do
				json.identifier patient.primary_provider_id
				json.name 'Practitioner'
			end
			json.on_behalf_of do
				json.identifier patient.business_entity_id
				json.name 'Organization'
			end
		end
	end

	json.entity do
		json.child! do
			json.identifier nil
			json.role nil
			json.what do
				json.identifier nil
				json.name nil
			end
		end
	end
end