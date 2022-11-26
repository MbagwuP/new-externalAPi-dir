json.documentReferenceEntriesList do
  json.array! @responses do |response|
    json.resource_count response[:count_summary] unless response[:count_summary].nil?
    json.documentReferenceEntries response[:resources].entries do |doc|
      doc = OpenStruct.new(doc)
      json.documentReference do
        json.identifier doc.id
        json.text doc.title
        json.status doc.full_status
        json.patient_name
        json.date response[:date] || doc.created_at

        json.description doc.description

        json.type do
          json.coding do
            json.array!([:once]) do
              json.code response[:type]

              json.code_system nil
              json.code_display nil
            end
          end
          json.text nil
        end

        json.category do
          json.coding do
            json.array!([:once]) do
              json.code response[:category]
              json.code_system nil
              json.code_display nil
            end
          end
          json.text nil
        end

        json.author do
          json.identifier doc.created_by
          json.name doc.creator_name
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
        json.partial! :patient, patient: OpenStruct.new(doc.patient)
        if @is_provenance_target_present
          json.partial! :_provenance, patient: OpenStruct.new(doc.patient), record: doc,
                        provider: OpenStruct.new(doc.provider), business_entity: OpenStruct.new(doc.business_entity), obj: 'Document'
        end
      end
    end
  end
end

