
  json.array! @responses do |response|
    json.resource_count response[:count_summary] unless response[:count_summary].nil?
    json.documentReferenceEntries response[:resources].entries do |doc|
      doc = OpenStruct.new(doc)
      patient = OpenStruct.new(doc.patient)
      json.documentReference do
        json.identifier doc.id
        json.text doc.title
        json.status doc.full_status == "A" ? "Current" : "Superseded"
        json.patient_name
        json.date doc.created_at

        json.description doc.description

        json.type do
          json.coding do
            json.array!([:once]) do
              json.code response[:type]
              json.code_system "loinc"
              json.code_display "Laboratory report"
            end
          end
          json.text nil
        end
        json.custodian do

          json.identifier current_business_entity
          json.name 'Organization'

        end

        json.category do
          json.coding do
            json.array!([:once]) do
              json.code response[:category]
              json.code_system "http://hl7.org/fhir/us/core/CodeSystem/us-core-documentreference-category"
              json.code_display "Clinical Note"
            end
          end
          json.text nil
        end


        json.context do
          json.encounter do
            json.identifier nil
            json.name "Encounter"
          end
          json.period do
            json.start doc.created_at
            json.end nil
          end
        end


        json.author do
          json.array! [:once] do
            json.identifier doc.created_by
            json.name doc.creator_name
          end
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
        json.account_number patient.external_id
        json.mrn patient.chart_number
        json.patient_name patient.full_name
        json.external_id patient.external_id
      end

      json.partial! :_provenance, patient: OpenStruct.new(doc.patient), record: doc,
                    provider: OpenStruct.new(doc.provider), business_entity: OpenStruct.new(doc.business_entity), obj: 'Document' if @is_provenance_target_present
    end
  end

