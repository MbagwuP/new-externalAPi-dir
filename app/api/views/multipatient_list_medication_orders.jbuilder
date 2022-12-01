
  json.array! @responses do |response|
    json.resource_count response[:count_summary] unless response[:count_summary].nil?
    json.medications response[:resources].entries do |medication|
      json.partial! :medication,
                    medication: OpenStruct.new(medication),
                    valid_intents: response[:include_intent_target],
                    valid_status: response[:include_status_target],
                    provenance: @include_provenance_target
    end
  end

