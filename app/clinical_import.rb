class ApiService < Sinatra::Base

#   {
#     "allergy": [
#         {
#             "rx_norm_code": null,
#             "onset_at": "2013-08-01T12:00:00-04:00",
#             "resolved_at": null,
#             "snomed_code": null,
#             "name": "Peanuts",
#             "status": "A",
#             "comments": "test test test test test test test test test test test test test test !!!@@@###",
#             "reaction": [
#                 {
#                     "description": "not bad",
#                     "severity_id": "1",
#                     "reaction_id": "14",
#                     "status": "A"
#                 },
#                 {
#                     "description": "freakish!!!!",
#                     "severity_id": "2",
#                     "reaction_id": "12",
#                     "status": "A"
#                 }
#             ]
#         }
#     ],
#     "immunizations": [
#         {
#             "immunization_name": "Diphtheria and Tetanus Toxoids and Acellular Pertussis Adsorbed, Inactivated Poliovirus, Haemophilus b Conjugate (Meningococcal Outer Membrane Protein Complex), and Hepatitis B (Recombinant) Vaccine.",
#             "immunization_description": "Diphtheria and Tetanus Toxoids and Acellular Pertussis Adsorbed, Inactivated Poliovirus, Haemophilus b Conjugate (Meningococcal Outer Membrane Protein Complex), and Hepatitis B (Recombinant) Vaccine.",
#             "immunization_code": "146",
#             "rx_norm_code": null,
#             "vaccine_administration_quantity": null,
#             "vaccine_administration_quantity_uom": null,
#             "vaccine_administration_quantity_uom_code": null,
#             "vaccine_manufacturer_name": null,
#             "vaccine_manufacturer_code": null,
#             "vaccine_lot_number": null,
#             "vaccine_expiration_date": null,
#             "administered_at": null,
#             "route_description": null,
#             "status": "A",
#             "comments": null,
#             "ndc_number": null
#         }
#     ],
#     "medication": [
#         {
#             "patient_id": "b0b3a1b9-533e-47cb-83c5-585b12d84676",
#             "drug_name": "Lipitor10mgoraltablet",
#             "rx_norm_code": "617312",
#             "rx_norm_code_qualifier": "CD",
#             "effective_from": "2013-08-30T12: 00: 00-04: 00",
#             "effective_to": null,
#             "drug_description": null,
#             "route_description": "oral",
#             "status": "A",
#             "strength_description": "10mg",
#             "frequency_abbreviation": null,
#             "frequency_admins_per_day": null,
#             "frequency_description": "daily",
#             "dose": "1.0",
#             "is_substitution_permitted": true,
#             "other_instructions": "Pleaseremindpatienttotakeaftermeals.",
#             "prescription_instructions": "1tabletdailyfor30daysaftermeals",
#             "refill_count": 0,
#             "ndc_code": "00071015523",
#             "quantity": "30.0",
#             "days_supply": null
#         }
#     ]
# }

post '/v1/patients/clinical/fullimport/:patient_id/create?' do

    local_pid = []
    resp = []
    # Validate the input parameters
    request_body = get_request_JSON
    local_pid = params['patient_id']
    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication]) 
    business_entity = get_business_entity(pass_in_token)
    patient_id = get_internal_patient_id(local_pid, business_entity, pass_in_token)
    id = patient_id


if request_body['allergy']
    request_body['allergy'].each do |newAL|
               Allergy = Hash.new
        Allergy['allergy'] = newAL

    urlallergies = ''
    urlallergies << API_SVC_URL
    urlallergies << 'patient_allergies/'
    urlallergies << business_entity
    urlallergies << '/patients/'
    urlallergies << patient_id
    urlallergies << '/id/'
    urlallergies << id
    urlallergies << '/patient_allergies.json?token='
    urlallergies << CGI::escape(params[:authentication])

    resp = generate_http_request(urlallergies, "", Allergy.to_json, "POST")
        response_code = map_response(resp.code)

    status response_code
    end

end
if request_body['immunization']
    request_body['immunization'].each do |newImm|
    Immunizations = Hash.new
    Immunizations['immunization'] = newImm
    urlimmunizations = ''
    urlimmunizations << API_SVC_URL
    urlimmunizations << 'patient_immmunizations/'
    urlimmunizations << business_entity
    urlimmunizations << '/patients/'
    urlimmunizations << patient_id
    urlimmunizations << '/patient_immmunizations.json?token='
    urlimmunizations << CGI::escape(params[:authentication])


    LOG.debug ("URL put together is: #{urlimmunizations} ")
    LOG.debug(request_body.to_json)

    resp = generate_http_request(urlimmunizations, "", Immunizations.to_json, "POST")

        response_code = map_response(resp.code)

    status response_code
    end   
end
    request_body['medication'].each do |newMed|
    Medications = Hash.new
    Medications['medication'] = newMed

    urlmedications = ''
    urlmedications << API_SVC_URL
    urlmedications << '/patients/'
    urlmedications << patient_id
    urlmedications << '/medications.json?token='
    urlmedications << CGI::escape(params[:authentication])

    resp = generate_http_request(urlmedications, "", Medications.to_json, "POST")

    end

    response_code = map_response(resp.code)

    status response_code
end


# {
#     "allergy": [
#         {
#             "rx_norm_code": null,
#             "onset_at": "2013-08-01T12:00:00-04:00",
#             "resolved_at": null,
#             "snomed_code": null,
#             "name": "Peanuts",
#             "status": "A",
#             "comments": "test test test test test test test test test test test test test test !!!@@@###",
#             "reaction": [
#                 {
#                     "description": "not bad",
#                     "severity": "1",
#                     "reaction": "14",
#                     "snomed_code": "267036007",
#                     "status": "A"
#                 },
#                 {
#                     "description": "freakish!!!!",
#                     "severity": "Major",
#                     "reaction": "12",
#                     "snomed_code": "278528006",
#                     "status": "A"
#                 }
#             ]
#         }
#     ]
# }


# #PatientAllergiesController#create

post '/v1/patients/:patient_id/allergies/create?' do

    local_pid = []
    resp = []
    # Validate the input parameters
    request_body = get_request_JSON
    local_pid = params['patient_id']
    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication]) 
    business_entity = get_business_entity(pass_in_token)
    patient_id = get_internal_patient_id(local_pid, business_entity, pass_in_token)
    id = patient_id

    request_body['allergy'].each do |newAllergy|
    Allergy = Hash.new
    Allergy['allergy'] = newAllergy
  
    urlallergies = ''
    urlallergies << API_SVC_URL
    urlallergies << 'patient_allergies/'
    urlallergies << business_entity
    urlallergies << '/patients/'
    urlallergies << patient_id
    urlallergies << '/id/'
    urlallergies << id
    urlallergies << '/patient_allergies.json?token='
    urlallergies << CGI::escape(params[:authentication])

    LOG.debug(request_body.to_json)

      resp = generate_http_request(urlallergies, "", Allergy.to_json, "POST")

    end

    response_code = map_response(resp.code)

    body(resp.body)

    status response_code
end


# {
#     "immunization": [
#         {
#     "immunization_name": "Diphtheria and Tetanus Toxoids and Acellular Pertussis Adsorbed, Inactivated Poliovirus, Haemophilus b Conjugate (Meningococcal Outer Membrane Protein Complex), and Hepatitis B (Recombinant) Vaccine.",
#     "immunization_description": "Diphtheria and Tetanus Toxoids and Acellular Pertussis Adsorbed, Inactivated Poliovirus, Haemophilus b Conjugate (Meningococcal Outer Membrane Protein Complex), and Hepatitis B (Recombinant) Vaccine.",
#     "immunization_code": "146",
#     "rx_norm_code": null,
#     "vaccine_administration_quantity": null,
#     "vaccine_administration_quantity_uom": null,
#     "vaccine_administration_quantity_uom_code": null,
#     "vaccine_manufacturer_name": null,
#     "vaccine_manufacturer_code": null,
#     "vaccine_lot_number": null,
#     "vaccine_expiration_date": null,
#     "administered_at": null,
#     "route_description": null,
#     "status": "A",
#     "comments": null,
#     "ndc_number": null
#         }
#     ]
# }

#PatientAllergiesController#create

post '/v1/patients/:patient_id/immunizations/create?' do

    resp = []
    local_pid = []
    # Validate the input parameters
    request_body = get_request_JSON
    local_pid = params['patient_id']
    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication]) 
    business_entity = get_business_entity(pass_in_token)
    patient_id = get_internal_patient_id(local_pid, business_entity, pass_in_token)

    request_body['immunization'].each do |newImm|
    Immunizations = Hash.new
    Immunizations['immunization'] = newImm

    urlimmunizations = ''
    urlimmunizations << API_SVC_URL
    urlimmunizations << 'patient_immmunizations/'
    urlimmunizations << business_entity
    urlimmunizations << '/patients/'
    urlimmunizations << patient_id
    urlimmunizations << '/patient_immmunizations.json?token='
    urlimmunizations << CGI::escape(params[:authentication])


    LOG.debug ("URL put together is: #{urlimmunizations} ")
    LOG.debug(request_body.to_json)

    resp = generate_http_request(urlimmunizations, "", Immunizations.to_json, "POST")

    end
    response_code = map_response(resp.code)

    body(resp.body)

    status response_code
end


# {
#     "medication": [
#         {
#             "patient_id": "b0b3a1b9-533e-47cb-83c5-585b12d84676",
#             "drug_name": "Lipitor10mgoraltablet",
#             "rx_norm_code": "617312",
#             "rx_norm_code_qualifier": "CD",
#             "effective_from": "2013-08-30T12: 00: 00-04: 00",
#             "effective_to": null,
#             "drug_description": null,
#             "route_description": "oral",
#             "status": "A",
#             "strength_description": "10mg",
#             "frequency_abbreviation": null,
#             "frequency_admins_per_day": null,
#             "frequency_description": "daily",
#             "dose": "1.0",
#             "is_substitution_permitted": true,
#             "other_instructions": "Pleaseremindpatienttotakeaftermeals.",
#             "prescription_instructions": "1tabletdailyfor30daysaftermeals",
#             "refill_count": 0,
#             "ndc_code": "00071015523",
#             "quantity": "30.0",
#             "days_supply": null
#         }
#     ]
# }

#MedicationsController#create

post '/v1/patients/:patient_id/medications/create?' do

    local_pid = []
    resp = []
    # Validate the input parameters
    request_body = get_request_JSON
    pass_in_token = CGI::unescape(params[:authentication]) 
    business_entity = get_business_entity(pass_in_token)
    local_pid = params[:patient_id]
    patient_id = get_internal_patient_id(local_pid, business_entity, pass_in_token)

    LOG.debug "Request Body >>>>>"
    LOG.debug(request_body)

    request_body['medication'].each do |newMed|

    if newMed['prescribed_quantity']
    newMed['quantity'] = newMed['prescribed_quantity']
    newMed.delete('prescribed_quantity')
    end

    LOG.debug "business_entity: "
    LOG.debug (business_entity)
    LOG.debug(local_pid)

    LOG.debug "patient_id: "
    LOG.debug(patient_id)
    newMed['patient_id'] = local_pid

    LOG.debug "Medication Object"
    LOG.debug(newMed)
    Medication = Hash.new
    Medication["medication"] = newMed
    LOG.debug(Medication)

    urlmedications = ''
    urlmedications << API_SVC_URL
    urlmedications << '/patients/'
    urlmedications << patient_id
    urlmedications << '/medications.json?token='
    urlmedications << CGI::escape(params[:authentication])

    resp = generate_http_request(urlmedications, "", Medication.to_json, "POST")
    LOG.debug(">>>>>>>>>>>>>>>>>>>>")
    LOG.debug(newMed.to_json)
    end


    response_code = map_response(resp.code)

    body(resp.body)

    status response_code

end


end