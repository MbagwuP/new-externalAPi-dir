json.resource_count @provenances.count
json.provenance @provenances do |provenance|
    if provenance[:obj] == "patient"
        json.partial! :patient_details_provenance, patient: provenance[:resource]
    else
        json.partial! :_provenance, patient: provenance[:patient], record: provenance[:resource], 
                provider: provenance[:provider], business_entity: provenance[:business_entity], obj: provenance[:obj]
    end
end
