json.resource_count @responses.count
json.condition @responses do |condition|

    first_condition = OpenStruct.new(condition)
    patient = OpenStruct.new(first_condition.patient)
    business_entity = OpenStruct.new(first_condition.business_entity)

      json.condition do
        json.partial! :condition, condition: OpenStruct.new(condition), patient: patient, account_number: patient.external_id
      end
      condition = OpenStruct.new(condition)
      if @is_provenance_target_present
        json.partial! :_provenance, patient: patient, record: condition,
                      provider: OpenStruct.new(condition.provider), business_entity: business_entity, obj: 'Condition'
      end

    json.patient do
      json.partial! :patient, patient: patient
    end

    json.business_entity do
      json.partial! :business_entity, business_entity: business_entity
    end
  end
