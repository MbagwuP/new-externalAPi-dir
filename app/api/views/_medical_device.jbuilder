#json.id medical_device.id
json.account_number @patient.external_id #.id
json.mrn @patient.chart_number
json.patient_name @patient.full_name

json.identifier medical_device.id
json.carrier_device_identifier medical_device.device_identifier
json.carrier_AIDC medical_device.unique_device_identifier
json.carrier_HRF medical_device.unique_device_identifier
json.status medical_device.full_status
json.manufacturer medical_device.company_name
json.manufacture_date medical_device.date_of_manufacture
json.expiration_date medical_device.expiration_date
json.lot_number medical_device.lot_number
json.serial_number medical_device.serial_number
json.device_name "#{medical_device.brand_name}, #{medical_device.gmdn_pt_name}"
json.model_number medical_device.version_model
json.type_code "704707009" #we need to add a field 'type_code'to ImplantableDevice table with the snomed code (medical_device.type_code)
json.type_code_system "snomed"
json.type_code_display medical_device.gmdn_pt_name
json.type_text medical_device.gmdn_pt_name
