
json.resource_count @responses.count
json.medications @responses do |response|
      json.partial! :medication,
                    medication: OpenStruct.new(response[:medication]),
                    valid_intents: @include_intent_target,
                    valid_status: @include_status_target,
                    provenance: @include_provenance_target
  end

