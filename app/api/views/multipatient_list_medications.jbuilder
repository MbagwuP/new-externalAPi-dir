
json.medication @responses do |response|
    json.resource_count response[:count_summary] unless response[:count_summary].nil?
      json.partial! :medication,
                    medication: OpenStruct.new(response[:medication]),
                    valid_intents: @include_intent_target,
                    valid_status: @include_status_target,
                    provenance: @include_provenance_target
  end

