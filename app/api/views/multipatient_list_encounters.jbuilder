
json.resource_count @responses.count
json.encounterEntries @responses do |response|
    @encounter = response
    @encounter["nature_of_visit"] = OpenStruct.new({name: @encounter["nature_of_visit"], code: nil, description: nil})
    json.encounter JSON.parse(jbuilder :show_encounter)['encounter']
end
