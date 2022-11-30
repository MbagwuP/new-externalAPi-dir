
  json.array! @responses do |conditions|
    first_condition = OpenStruct.new(conditions.first)
    patient = OpenStruct.new(first_condition.patient)
    business_entity = OpenStruct.new(first_condition.business_entity)

    json.conditionEntries conditions do |condition|
      json.resource_count condition[:count_summary] unless condition[:count_summary].nil?
      json.condition do
        json.partial! :condition, condition: OpenStruct.new(condition), patient: patient, account_number: patient.external_id
      end
      condition = OpenStruct.new(condition)
      if @is_provenance_target_present
        json.partial! :_provenance, patient: patient, record: condition,
                      provider: OpenStruct.new(condition.provider), business_entity: business_entity, obj: 'Condition'
      end
    end

    json.patient do
      json.partial! :patient, patient: patient
    end

    json.business_entity do
      json.partial! :business_entity, business_entity: business_entity
    end
  end
