first_condition = OpenStruct.new(@conditions.first)
patient = OpenStruct.new(first_condition.patient)
business_entity = OpenStruct.new(first_condition.business_entity)

json.resource_count @count_summary unless @count_summary.nil?
json.conditionEntries @conditions do |condition|
  json.condition do 
    json.partial! :condition, condition: OpenStruct.new(condition), patient: patient, account_number: @acc_number
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