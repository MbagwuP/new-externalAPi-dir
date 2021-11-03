provider = OpenStruct.new(allergy.provider)
reactions = allergy.allergy_reactions

json.id allergy.id
json.clinical_status allergy.status
json.verification_status ''
json.type 'allergy'
json.category allergy.allergen_class
json.criticality 'unable-to-assess-risk'
json.onset allergy.onset_date
json.date_recorded allergy.created_at

json.code allergy.snomed_code
json.code_system 'snomed'
json.code_display allergy.name

json.reaction reactions do |reaction|
  json.reaction_code reaction['reaction_snomed_code']
  json.reaction_code_display reaction['reaction']
  json.reaction_severity reaction['severity']
end

json.provider do
  json.partial! :provider, provider: provider
end
