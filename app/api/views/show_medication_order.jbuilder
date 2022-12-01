medication = OpenStruct.new(@medication)

json.medication do
  json.partial! :medication, medication: medication,
                valid_intents: @include_intent_target,
                valid_status: @include_status_target,
                provenance: @include_provenance_target
end
