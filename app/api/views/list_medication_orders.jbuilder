first_medication = OpenStruct.new(@medications.first)

json.medications @medications do |medication|

  json.partial! :medication, medication: OpenStruct.new(medication), valid_intents: @include_intent_target, valid_status: @include_status_target, provenance: @include_provenance_target
end
