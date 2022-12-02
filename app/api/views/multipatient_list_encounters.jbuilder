
json.encounterEntries @responses do |response|
    @encounter = response
    @encounter["nature_of_visit"] = OpenStruct.new({name: @encounter["nature_of_visit"], code: nil, description: nil})
    json.resource_count response[:count_summary] unless response[:count_summary].nil?

    json.encounter JSON.parse(jbuilder :show_encounter)['encounter']
end
