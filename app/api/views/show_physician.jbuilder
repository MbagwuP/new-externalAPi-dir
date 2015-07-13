json.physician do
	json.npi @physician['npi']	
	json.prefix @physician['prefix']
	json.first_name @physician['first_name']
	json.middle_initial @physician['middle_initial']
	json.last_name @physician['last_name']
	json.suffix @physician['suffix']
	json.email @physician['email']
	json.gender_code cc_id_to_code('gender', @physician['gender_id'])
	json.deactivation_date @physician['deactivation_date']
	if @physician['is_organization']
		json.organiziation do 
			json.name @physician['organiziation_name']
			json.official_email @physician['organization_official_email']
			json.official_first_name @physician['organization_official_first_name']
			json.official_last_name @physician['organization_official_last_name']
			json.official_middle_initial @physician['organization_official_middle_initial']
			json.official_phone @physician['organization_official_phone']
			json.official_prefix @physician['organization_official_prefix']
			json.official_suffix @physician['organization_official_suffix']
			json.offical_title @physician['organization_official_title']
		end
	else
		json.organiziation nil
	end
end