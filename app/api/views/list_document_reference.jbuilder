json.document_reference_entries @documents do |doc|
  doc = OpenStruct.new(doc)

  json.identifier doc.id
  json.text doc.title
  json.status doc.full_status
  json.date doc.created_at
  json.description doc.description

  json.type_code nil
  json.type_code_system nil
  json.type_code_display nil

  json.category_code 'clinical-note'
  json.category_code_system 'http://hl7.org/fhir/us/core/CodeSystem/us-core-documentreference-category'
  json.category_code_display 'Clinical Note'

  json.author do
    json.identifier doc.created_by
    json.name doc.creator_name
  end

  json.content do
    json.url doc.document_url
    json.hash doc.document_handler
    json.document_format doc.document_format
    json.title doc.title
  end
  
  json.patient do
    json.partial! :patient, patient: OpenStruct.new(doc.patient)
  end
end

