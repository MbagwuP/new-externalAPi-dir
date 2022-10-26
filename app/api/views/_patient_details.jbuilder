address = OpenStruct.new(patient.primary_address)
previous_address = OpenStruct.new(patient.previous_home_address)
phone = OpenStruct.new(patient.phones)
guarantor = OpenStruct.new(patient.responsible_party)
guarantor_address = OpenStruct.new(guarantor.try(:addresses).try(:first))
guarantor_phones = OpenStruct.new(guarantor.try(:phones))
primary_location = OpenStruct.new(patient.primary_location)
json.patient do 
	json.account_number patient.external_id
	json.internal_identifier patient.external_id
	json.mrn patient.chart_number
	json.secondary_mrn nil
	json.tertiary_mrn nil
	json.first_name patient.first_name
	json.last_name patient.last_name
	json.middle_name patient.middle_name
	json.prefix patient.prefix
	json.suffix patient.suffix
	json.preferred_name patient.preferred_name
	json.previous_first_name patient.previous_name
	json.previous_last_name nil

	json.healthcare_entity do
		json.identifier patient.business_entity_id
  	json.name patient.business_entity_name
	end

	json.race do
		json.name patient.race
		json.code patient.race_code
		json.coding_system "Race & Ethnicity - CDC"
	end

	json.ethnicity do
		json.name patient.ethnicity
		json.code patient.ethnicity_code
		json.coding_system "Race & Ethnicity - CDC"
	end

	json.date_of_birth patient.dob
	json.age patient.dob.present? ? (Date.today.year - patient.dob.to_date.year) : nil
	json.gender patient.gender
	json.birth_sex (patient.gender == 'female' ? 'F' : 'M')

	json.marital_status do
		json.name patient.marital_status
		json.code patient.marital_status_code
	end

	json.ssn patient.ssn
	json.email_address patient.email_address
	json.status patient.status
	json.date_of_death patient.date_of_death
	json.last_seen_date patient.last_seen_date
	json.drivers_license_number patient.drivers_license_number
	json.mother_maiden_name patient.mother_maiden_name

	json.language do
		json.name patient.language
		json.code patient.language_code
		json.coding_system "ISO 639-2 Language"
	end

	json.primary_location do
		json.identifier primary_location.try(:id)
		json.name primary_location.try(:name)
	end

	json.primary_provider do
		json.identifier patient.primary_provider_id
		json.npi patient.primary_provider_npi
		json.first_name patient.primary_provider_first_name
		json.last_name patient.primary_provider_last_name
	end

	json.referring_physician do
		json.identifier patient.referring_physician_id
		json.npi patient.referring_physician_npi
		json.first_name patient.referring_physician_first_name
		json.last_name patient.referring_physician_last_name
		json.middle_name patient.referring_physician_middle_name
	end

	json.primary_care_physician do
		json.identifier patient.primary_care_physician_id
		json.npi patient.primary_care_physician_npi
		json.first_name patient.primary_care_physician_first_name
		json.last_name patient.primary_care_physician_last_name
		json.middle_name patient.primary_care_physician_middle_name
	end

	json.address do
		json.line1 address.try(:line1)
		json.line2 address.try(:line2)
		json.state_code address.try(:state_code)
		json.city address.try(:city)
	  json.zip address.try(:zip)
	  json.country_name address.try(:country_name)
	  json.period do
	  	json.start address.try(:validated_at)
	  	json.end nil
	  end
	end

	json.previous_address do
		json.line1 previous_address.try(:line1)
		json.line2 previous_address.try(:line2)
		json.state_code previous_address.try(:state_code)
		json.city previous_address.try(:city)
	  json.zip previous_address.try(:zip)
	  json.country_name previous_address.try(:country_name)
	  json.period do
	  	json.start previous_address.try(:validated_at)
	  	json.end nil
	  end
	end

	json.phones do
		json.home phone.try(:home_phone)
		json.work nil
		json.cellphone phone.try(:cell_phone)
		json.main phone.try(:main_phone)
		json.business phone.try(:business_phone)
	end

	json.guarantor do
		json.relationship_to_patient_code_name guarantor.responsible_party_person_relationship_type_name
		json.relationship_to_patient_code_identifier guarantor.responsible_party_person_relationship_type_id
		json.code guarantor.responsible_party_person_relationship_type_code
		json.first_name guarantor.first_name
		json.last_name guarantor.last_name
		json.middle_name guarantor.middle_name
		json.date_of_birth guarantor.dob
		json.gender guarantor.gender
		json.ssn nil
		json.address do
			json.line1 guarantor_address.line1
			json.line2 guarantor_address.line2
			json.state_code guarantor_address.state_code
			json.city guarantor_address.city
			json.zip guarantor_address.zip
			json.country_name guarantor_address.country_name
		end
		json.phones do
			json.home guarantor_phones.try(:home_phone)
			json.work nil
			json.cellphone guarantor_phones.try(:cell_phone)
			json.main guarantor_phones.try(:main_phone)
			json.business guarantor_phones.try(:business_phone)
		end
	end

	primary_policy = OpenStruct.new(patient.primary_policy)
	secondary_policy = OpenStruct.new(patient.secondary_policy)
	tertiary_policy = OpenStruct.new(patient.tertiary_policy)
	json.insurance_information do
		json.primary_policy do
			json.member_number primary_policy.try(:member_number)
			payer = OpenStruct.new(primary_policy.try(:payer))
			json.payer_plan do
				json.identifier payer.try(:id)
				json.name payer.try(:name)
				json.address payer.try(:line1)
				json.city payer.try(:city)
				json.state payer.try(:state_code)
				json.zip payer.try(:zip)
			end
			json.policy_number primary_policy.try(:policy_number)
			json.group_name primary_policy.try(:group_name)
			json.group_number nil
			json.effective_from primary_policy.try(:effective_from)
			json.effective_to primary_policy.try(:effective_to)
			subscriber = OpenStruct.new(primary_policy.try(:insured_contact))
			json.insured_subscriber do
				json.relationship_to_patient_code_name subscriber.try(:insured_relationship_code_name)
				json.relationship_to_patient_code_identifier subscriber.try(:insured_relationship_code_id)
				json.first_name subscriber.try(:first_name)
				json.last_name subscriber.try(:last_name)
				json.middle_name subscriber.try(:middle_name)
				json.date_of_birth subscriber.try(:dob)
				json.gender subscriber.try(:gender)
				json.ssn subscriber.try(:ssn)
				policy_address = OpenStruct.new(subscriber.try(:address))
				json.address do
					json.line1 policy_address.try(:line1)
					json.line2 policy_address.try(:line2)
					json.state_code policy_address.try(:state_code)
					json.city policy_address.try(:city)
					json.zip policy_address.try(:zip)
					json.country_name policy_address.try(:country_name)
				end
				policy_phone = OpenStruct.new(subscriber.try(:phones))
				json.phones do
					json.home policy_phone.try(:home_phone)
					json.work nil
					json.cellphone policy_phone.try(:cell_phone)
					json.main  policy_phone.try(:main_phone)
					json.business policy_phone.try(:business_phone)
				end
			end
		end

		json.secondary_policy do
			json.member_number secondary_policy.try(:member_number)
			payer = OpenStruct.new(secondary_policy.try(:payer))
			json.payer_plan do
				json.identifier payer.try(:id)
				json.name payer.try(:name)
				json.address payer.try(:line1)
				json.city payer.try(:city)
				json.state payer.try(:state_code)
				json.zip payer.try(:zip)
			end
			json.policy_number secondary_policy.try(:policy_number)
			json.group_name secondary_policy.try(:group_name)
			json.group_number nil
			json.effective_from secondary_policy.try(:effective_from)
			json.effective_to secondary_policy.try(:effective_to)
			subscriber = OpenStruct.new(secondary_policy.try(:insured_contact))
			json.insured_subscriber do
				json.relationship_to_patient_code_name subscriber.try(:insured_relationship_code_name)
				json.relationship_to_patient_code_identifier subscriber.try(:insured_relationship_code_id)
				json.first_name subscriber.try(:first_name)
				json.last_name subscriber.try(:last_name)
				json.middle_name subscriber.try(:middle_name)
				json.date_of_birth subscriber.try(:dob)
				json.gender subscriber.try(:gender)
				json.ssn subscriber.try(:ssn)
				policy_address = OpenStruct.new(subscriber.try(:address))
				json.address do
					json.line1 policy_address.try(:line1)
					json.line2 policy_address.try(:line2)
					json.state_code policy_address.try(:state_code)
					json.city policy_address.try(:city)
					json.zip policy_address.try(:zip)
					json.country_name policy_address.try(:country_name)
				end
				policy_phone = OpenStruct.new(subscriber.try(:phones))
				json.phones do
					json.home policy_phone.try(:home_phone)
					json.work nil
					json.cellphone policy_phone.try(:cell_phone)
					json.main  policy_phone.try(:main_phone)
					json.business policy_phone.try(:business_phone)
				end
			end
		end

		json.tertiary_policy do
			json.member_number tertiary_policy.try(:member_number)
			payer = OpenStruct.new(tertiary_policy.try(:payer))
			json.payer_plan do
				json.identifier payer.try(:id)
				json.name payer.try(:name)
				json.address payer.try(:line1)
				json.city payer.try(:city)
				json.state payer.try(:state_code)
				json.zip payer.try(:zip)
			end
			json.policy_number tertiary_policy.try(:policy_number)
			json.group_name tertiary_policy.try(:group_name)
			json.group_number nil
			json.effective_from tertiary_policy.try(:effective_from)
			json.effective_to tertiary_policy.try(:effective_to)
			subscriber = OpenStruct.new(tertiary_policy.try(:insured_contact))
			json.insured_subscriber do
				json.relationship_to_patient_code_name subscriber.try(:insured_relationship_code_name)
				json.relationship_to_patient_code_identifier subscriber.try(:insured_relationship_code_id)
				json.first_name subscriber.try(:first_name)
				json.last_name subscriber.try(:last_name)
				json.middle_name subscriber.try(:middle_name)
				json.date_of_birth subscriber.try(:dob)
				json.gender subscriber.try(:gender)
				json.ssn subscriber.try(:ssn)
				policy_address = OpenStruct.new(subscriber.try(:address))
				json.address do
					json.line1 policy_address.try(:line1)
					json.line2 policy_address.try(:line2)
					json.state_code policy_address.try(:state_code)
					json.city policy_address.try(:city)
					json.zip policy_address.try(:zip)
					json.country_name policy_address.try(:country_name)
				end
				policy_phone = OpenStruct.new(subscriber.try(:phones))
				json.phones do
					json.home policy_phone.try(:home_phone)
					json.work nil
					json.cellphone policy_phone.try(:cell_phone)
					json.main  policy_phone.try(:main_phone)
					json.business policy_phone.try(:business_phone)
				end
			end
		end
	end

end

if include_provenance_target
	json.partial! :patient_details_provenance, patient: patient
end