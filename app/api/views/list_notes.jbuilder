json.notes @notes['notes'] do |note|
    json.partial! :note, note: note
  end