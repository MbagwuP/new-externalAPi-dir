json.id medical_device.id
json.status medical_device.full_status
json.carrier_device_identifier medical_device.device_identifier
json.manufacturer medical_device.company_name
json.manufacture_date medical_device.date_of_manufacture
json.expiration_date medical_device.expiration_date
json.lot_number medical_device.lot_number
json.serial_number medical_device.serial_number
json.model_number medical_device.version_model
json.device_name "#{medical_device.brand_name}, #{medical_device.gmdn_pt_name}"


json.carrier_AIDC medical_device.unique_device_identifier
json.carrier_HRF nil
json.type_code nil
json.type_code_system nil
json.type_code_display nil
json.type_text nil
