json.documentReferenceEntries @documents do |doc|
  doc = OpenStruct.new(doc)
  json.documentReference do
    json.identifier doc.id
    json.text doc.title
    json.status doc.full_status
    json.date doc.created_at
    json.description doc.description

    json.type do
      json.coding do
        json.array!([:once]) do
          json.code nil
          json.code_system nil
          json.code_display nil
        end
      end
      json.text nil
    end

    json.category do
      json.coding do
        json.array!([:once]) do
          json.code nil
          json.code_system nil
          json.code_display nil
        end
      end
      json.text nil
    end

    json.category do
      json.coding do
        json.array!([:once]) do
          json.code 'clinical-note'
          json.code_system 'http://hl7.org/fhir/us/core/CodeSystem/us-core-documentreference-category'
          json.code_display 'Clinical Note'
        end
      end
      json.text nil
    end

    json.context do
      json.encounter do
        json.identifier nil
        json.name nil
      end
      json.period do
        json.start nil
        json.end nil
      end
    end

    
    json.author do
      json.identifier doc.created_by
      json.name doc.creator_name
    end

    json.content do
      json.array! [:once] do
        json.attachment do
          json.content_type doc.document_format
          json.data RestClient.get(doc.document_url).to_s
        end
        json.format do
          json.code 'urn:ihe:iti:xds:2017:mimeTypeSufficient'
          json.code_system nil
          json.code_display 'mimeType Sufficient'
        end
      end
    end
    
    json.patient do
      json.partial! :patient, patient: OpenStruct.new(doc.patient)
    end
  end
end

