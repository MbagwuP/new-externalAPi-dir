medication = OpenStruct.new(@medication)

json.partial! :medication, medication: medication,
  valid_intents: @include_intent_target,
  valid_status: @include_status_target,
  provenance: @include_provenance_target
