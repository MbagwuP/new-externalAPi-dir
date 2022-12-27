position_of_care_plan=0
  
json.resource_count @count_summary unless @count_summary.nil?
json.carePlanEntries @plan_of_treatment.entries do |carePlan|
  patient = OpenStruct.new(@patient)
  provider = OpenStruct.new(@provider)
  business_entity = OpenStruct.new(@business_entity)
  contact = OpenStruct.new(@contact)
  care_plan_code = OpenStruct.new(carePlan.code)

  category_care_plan_code = [[care_plan_code.code, "snomed", care_plan_code.displayName], ["assess-plan", "http://hl7.org/fhir/us/core/CodeSystem/careplan-category", "careplan-category"]]
  position_of_care_plan = position_of_care_plan+1

  json.carePlan do
    json.account_number patient.external_id
    json.mrn patient.chart_number
    json.patient_name contact.first_name + " " + contact.middle_name + " " + contact.last_name
    json.identifier "#{patient.external_id}-CarePlan-#{position_of_care_plan}"
    json.text carePlan.title
    json.text_status "generated"
    json.status carePlan.status
    json.intent 'order'

    json.category do
      json.coding do
        json.array!(category_care_plan_code) do |category_code|
          json.code category_code[0]
          json.code_system category_code[1]
          json.code_display category_code[2]
        end
      end
    end

    json.period_start carePlan.start_date
    json.period_end nil
    
    json.encounter do
      json.reference
    end

    json.addresses do
      json.reference
    end

    json.provider do
      json.identifier provider.try(:id)	
      json.npi provider.try(:npi)
      json.last_name provider.try(:last_name)
      json.first_name provider.try(:first_name)
    end

    json.healthcare_entity do
      json.identifier business_entity.id
      json.name business_entity.name
    end
  end

  if @include_provenance_target
	  json.partial! :_provenance, patient: patient, record: carePlan,
    provider: provider, business_entity: business_entity,
		obj: 'CarePlan'
  end
end