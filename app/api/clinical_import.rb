class ApiService < Sinatra::Base

  #{
  #    "allergy": [
  #    {
  #        "rx_norm_code": null,
  #"onset_at": "2013-08-01T12:00:00-04:00",
  #    "resolved_at": null,
  #"snomed_code": null,
  #"name": "Peanuts",
  #    "status": "A",
  #    "comments": "test test test test test test test test test test test test test test !!!@@@###",
  #    "reaction": [
  #    {
  #        "description": "not bad",
  #    "severity_id": "1",
  #    "reaction_id": "14",
  #    "status": "A"
  #},
  #    {
  #        "description": "freakish!!!!",
  #    "severity_id": "2",
  #    "reaction_id": "12",
  #    "status": "A"
  #}
  #]
  #}
  #],
  #    "immunization": [
  #    {
  #        "immunization_name": "Diphtheria and Tetanus Toxoids and Acellular Pertussis Adsorbed, Inactivated Poliovirus, Haemophilus b Conjugate (Meningococcal Outer Membrane Protein Complex), and Hepatitis B (Recombinant) Vaccine.",
  #    "immunization_description": "Diphtheria and Tetanus Toxoids and Acellular Pertussis Adsorbed, Inactivated Poliovirus, Haemophilus b Conjugate (Meningococcal Outer Membrane Protein Complex), and Hepatitis B (Recombinant) Vaccine.",
  #    "immunization_code": "146",
  #    "rx_norm_code": null,
  #"vaccine_administration_quantity": null,
  #"vaccine_administration_quantity_uom": null,
  #"vaccine_administration_quantity_uom_code": null,
  #"vaccine_manufacturer_name": null,
  #"vaccine_manufacturer_code": null,
  #"vaccine_lot_number": null,
  #"vaccine_expiration_date": null,
  #"administered_at": null,
  #"route_description": null,
  #"status": "A",
  #    "comments": null,
  #"ndc_number": null
  #}
  #],
  #    "medication": [
  #    {
  #        "drug_name": "Lipitor10mgoraltablet",
  #    "rx_norm_code": "617312",
  #    "rx_norm_code_qualifier": "CD",
  #    "effective_from": "2013-08-30T12: 00: 00-04: 00",
  #    "effective_to": null,
  #"drug_description": null,
  #"route_description": "oral",
  #    "status": "A",
  #    "strength_description": "10mg",
  #    "frequency_abbreviation": null,
  #"frequency_admins_per_day": null,
  #"frequency_description": "daily",
  #    "dose": "1.0",
  #    "is_substitution_permitted": true,
  #"other_instructions": "Pleaseremindpatienttotakeaftermeals.",
  #    "prescription_instructions": "1tabletdailyfor30daysaftermeals",
  #    "refill_count": 0,
  #    "ndc_code": "00071015523",
  #    "quantity": "30.0",
  #    "days_supply": null
  #}
  #],
  #    "problem": [
  #    {
  #        "snomed_code": "21983002",
  #    "icd9": "245.2",
  #    "name": "Thyroiditis, hashimotos",
  #    "description": null,
  #"onset_at": "2013-09-04T13:00:00-04:00",
  #    "resolved_at": null,
  #"status": "A"
  #}
  #]
  #}

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


        begin
          response = RestClient.post(urlallergies , Allergy.to_json, :content_type => :json)
        rescue => e
          begin
            exception = error_handler_filter(e.response)
            errmsg = "Updating Patient Data Failed - #{exception}"
            api_svc_halt e.http_code, errmsg
          rescue
            errmsg = "Updating Patient Data Failed - #{e.message}"
            api_svc_halt HTTP_INTERNAL_ERROR, errmsg
          end
        end
        status HTTP_CREATED
      end
    end

    if request_body['immunization']
      request_body['immunization'].each do |newImm|
        Immunizations = Hash.new
        Immunizations['immunization'] = newImm
        urlimmunizations = ''
        urlimmunizations << API_SVC_URL
        urlimmunizations << 'patient_immunizations/'
        urlimmunizations << business_entity
        urlimmunizations << '/patients/'
        urlimmunizations << patient_id
        urlimmunizations << '/patient_immunizations.json?token='
        urlimmunizations << CGI::escape(params[:authentication])


        begin
          response = RestClient.post(urlimmunizations , Immunizations.to_json, :content_type => :json)
        rescue => e
          begin
            exception = error_handler_filter(e.response)
            errmsg = "Updating Patient Data Failed - #{exception}"
            api_svc_halt e.http_code, errmsg
          rescue
            errmsg = "Updating Patient Data Failed - #{e.message}"
            api_svc_halt HTTP_INTERNAL_ERROR, errmsg
          end
        end

        status HTTP_OK
      end
    end

    if request_body['problem']
      request_body['problem'].each do |newProb|
        Problems = Hash.new
        Problems['problem'] = newProb
        Problems['problem']['icd_indicator'] = validate_icd_indicator(Problems['problem']['icd_indicator'])

        urlproblems = ''
        urlproblems << API_SVC_URL
        urlproblems << 'patient_assertions/'
        urlproblems << business_entity
        urlproblems << '/patients/'
        urlproblems << patient_id
        urlproblems << '/create/'
        urlproblems << '/problems.json?token='
        urlproblems << CGI::escape(params[:authentication])


        begin
          response = RestClient.post(urlproblems , Problems.to_json, :content_type => :json)
        rescue => e
          begin
            exception = error_handler_filter(e.response)
            errmsg = "Updating Patient Data Failed - #{exception}"
            api_svc_halt e.http_code, errmsg
          rescue
            errmsg = "Updating Patient Data Failed - #{e.message}"
            api_svc_halt HTTP_INTERNAL_ERROR, errmsg
          end
        end
        status HTTP_OK
      end
    end

    request_body['medication'].each do |newMed|
      medications = Hash.new
      medications['medication'] = newMed

      urlmedications = ''
      urlmedications << API_SVC_URL
      urlmedications << '/patients/'
      urlmedications << patient_id
      urlmedications << '/medications.json?token='
      urlmedications << CGI::escape(params[:authentication])

      begin
        response = RestClient.post(urlmedications , medications.to_json, :content_type => :json)
      rescue => e
        begin
          exception = error_handler_filter(e.response)
          errmsg = "Medications Creation Failed - #{exception}"
          api_svc_halt e.http_code, errmsg
        rescue
          errmsg = "Updating Patient Data Failed - #{e.message}"
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end
    end
    body('"Success":"Clinical Import has been created"')
    status HTTP_CREATED
  end

#
# {
#    "allergy": [
#    {
#        "rx_norm_code": null,
# "onset_at": "2013-08-01T12:00:00-04:00",
#    "resolved_at": null,
# "snomed_code": null,
# "name": "Peanuts",
#    "status": "A",
#    "comments": "test test test test test test test test test test test test test test !!!@@@###",
#    "reaction": [
#    {
#        "description": "not bad",
#    "severity_id": "1",
#    "reaction_id": "14",
#    "status": "A"
# },
#    {
#        "description": "freakish!!!!",
#    "severity_id": "2",
#    "reaction_id": "12",
#    "status": "A"
# }
# ]
# }
# ]
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
    failed = []
    success = 0

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

      begin
        response = RestClient.post(urlallergies, Allergy.to_json, :content_type => :json)
        success += 1
      rescue => e
        begin
          exception = error_handler_filter(e.response)
          failed.push({:allergy_name => newAllergy['name'], :error_msg => exception })
        rescue
          failed.push({:allergy_name => newAllergy['name']})
        end
      end
    end
    body('"Success":"Allergy Records has been created"')
    body('{"Patient identifier":"'+params[:patient_id]+'","Success":"'+"#{success}"+' Allergens created", "Failures":'+"#{failed.to_json}"+'}') if failed.size > 0
    status HTTP_CREATED

  end

#
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
      urlimmunizations << 'patient_immunizations/'
      urlimmunizations << business_entity
      urlimmunizations << '/patients/'
      urlimmunizations << patient_id
      urlimmunizations << '/patient_immunizations.json?token='
      urlimmunizations << CGI::escape(params[:authentication])

      begin
        response = RestClient.post(urlimmunizations, Immunizations.to_json, :content_type => :json)
      rescue => e
        begin
          exception = error_handler_filter(e.response)
          errmsg = "Medications Creation Failed - #{exception}"
          api_svc_halt e.http_code, errmsg
        rescue
          errmsg = "Immunizations Creation Failed - #{e.message}"
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end
    end
    body('"Success":" Immunization has been created"')
    status HTTP_CREATED
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
    failed = []
    success = 0
    #LOG.debug "Request Body >>>>>"
    #LOG.debug(request_body)

    request_body['medication'].each do |newMed|

      if newMed['prescribed_quantity']
        newMed['quantity'] = newMed['prescribed_quantity']
        newMed.delete('prescribed_quantity')
      end

      #LOG.debug "business_entity: "
      #LOG.debug (business_entity)
      #LOG.debug(local_pid)

      #LOG.debug "patient_id: "
      #LOG.debug(patient_id)
      newMed['patient_id'] = local_pid

      #LOG.debug "Medication Object"
      #LOG.debug(newMed)
      medications = Hash.new
      medications["medication"] = newMed
      #LOG.debug(Medication)

      urlmedications = ''
      urlmedications << API_SVC_URL
      urlmedications << '/patients/'
      urlmedications << patient_id
      urlmedications << '/medications.json?token='
      urlmedications << CGI::escape(params[:authentication])

      begin
        response = RestClient.post(urlmedications, medications.to_json, :content_type => :json)
        success += 1
      rescue => e
        begin
          exception = error_handler_filter(e.response)
          failed.push({:medication_name => newMed['drug_name'], :error_msg => exception })
        rescue
          failed.push({:medication_name => newMed['drug_name']})
        end
      end
    end
    body('"Success":"Medications has been created"')
    body('{"Patient identifier":"'+params[:patient_id]+'","Success":"'+"#{success}"+' Medications have been created", "Failures":'+"#{failed.to_json}"+'}') if failed.size > 0

    status HTTP_CREATED

  end

#{
#     "vitals": [
#         {
#             "name": "Vitals",
#             "started_at": "Nov 16, 2013 11:12:00 AM",
#             "observations": [
#                 {
#                     "status": "A",
#                     "observation_type_id": "4",
#                     "value": "80",
#                     "value_uom_id": "558"
#                 },
#                 {
#                     "status": "A",
#                     "observation_type_id": "1",
#                     "value": "88",
#                     "value_uom_id": "74"
#                 },
#                 {
#                     "status": "A",
#                     "observation_type_id": "3",
#                     "value": "60",
#                     "value_uom_id": "299"
#                 },
#                 {
#                     "status": "A",
#                     "observation_type_id": "2",
#                     "value": "30",
#                     "value_uom_id": "299"
#                 },
#                 {
#                     "status": "A",
#                     "observation_type_id": "5",
#                     "value": "1",
#                     "value_uom_id": "559"
#                 },
#                 {
#                     "status": "A",
#                     "observation_type_id": "6",
#                     "value": "50",
#                     "value_uom_id": "160"
#                 },
#                 {
#                     "status": "A",
#                     "observation_type_id": "7",
#                     "value": "1973",
#                     "value_uom_id": "372"
#                 }
#             ]
#         }
#     ]
#}

  post '/v1/patients/:patient_id/vitals/create?' do

    local_pid = []
    resp = []
    # Validate the input parameters
    request_body = get_request_JSON
    local_pid = params['patient_id']
    ## token management. Need unencoded tokens!
    pass_in_token = CGI::unescape(params[:authentication])
    business_entity = get_business_entity(pass_in_token)
    patient_id = get_internal_patient_id(local_pid, business_entity, pass_in_token)

    request_body['vitals'].each do |newVitals|
      Vitals = Hash.new
      Vitals['vitals'] = newVitals

      urlvitals = ''
      urlvitals << API_SVC_URL
      urlvitals << 'patient_vitals/'
      urlvitals << business_entity
      urlvitals << '/patients/'
      urlvitals << patient_id
      urlvitals << '/create/vitals.json?token='
      urlvitals << CGI::escape(params[:authentication])

      begin
        response = RestClient.post(urlvitals, Vitals.to_json, :content_type => :json)
      rescue => e
        begin
          exception = error_handler_filter(e.response)
          errmsg = "Vitals Creation Failed - #{exception}"
          api_svc_halt e.http_code, errmsg
        rescue
          errmsg = "Vitals Creation Failed - #{e.message}"
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end
    end

    body('"Success":" Vital has been created"')
    status HTTP_CREATED
  end



  #"problem":[
  #   {
  #        "snomed_code": "21983002",
  #        "icd9": "245.2",
  #        "name": "Thyroiditis, hashimotos",
  #        "description": null,
  #        "onset_at": "2013-09-04T13:00:00-04:00",
  #        "resolved_at": null,
  #        "status": "A"
  #}]

  post '/v1/patients/:patient_id/problems/create?' do

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

    request_body['problem'].each do |problem|

      #LOG.debug "business_entity: "
      #LOG.debug (business_entity)
      #LOG.debug(local_pid)

      #LOG.debug "patient_id: "
      #LOG.debug(patient_id)
      problem['patient_id'] = local_pid

      #LOG.debug "Problem Object"
      #LOG.debug(problem)
      Problems = Hash.new
      Problems["problem"] = problem
      #LOG.debug(Problem)

      Problems['problem']['icd_indicator'] = validate_icd_indicator(Problems['problem']['icd_indicator'])

      urlproblems = ''
      urlproblems << API_SVC_URL
      urlproblems << 'patient_assertions/'
      urlproblems << business_entity
      urlproblems << '/patients/'
      urlproblems << patient_id
      urlproblems << '/create/'
      urlproblems << 'problems.json?token='
      urlproblems << CGI::escape(params[:authentication])


      begin
        response = RestClient.post(urlproblems, Problems.to_json, :content_type => :json)
      rescue => e
        begin
          exception = error_handler_filter(e.response)
          errmsg = "Patient Creation Failed - #{exception}"
          api_svc_halt e.http_code, errmsg
        rescue
          errmsg = "Problem Set Creation Failed - #{e.message}"
          api_svc_halt HTTP_INTERNAL_ERROR, errmsg
        end
      end
    end
    body('"Success":" Problem set has been created"')
    status HTTP_CREATED

  end

end