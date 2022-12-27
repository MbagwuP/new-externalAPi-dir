doc = OpenStruct.new @document
patient = OpenStruct.new(doc.patient)
provider = OpenStruct.new(doc.provider)

  json.documentReference do
    json.identifier doc.id
    json.text doc.title
    json.status doc.full_status == "A" ? "Current" : "Superseded"
    json.date doc.created_at
    json.description doc.description

    json.type do
      json.coding do
        json.array!([:once]) do
          json.code @type
          json.code_system "loinc"
          json.code_display "Laboratory report"
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
        json.name "Encounter"
      end
      json.period do
        json.start doc.created_at
        json.end nil
      end
    end
    json.custodian do
		  json.identifier doc.business_entity["id"]
		  json.name 'Organization'
    end

    json.author do
      json.array! [:once] do
        json.identifier provider['id']
        json.name "Practitioner"
      end
    end

    json.content do
      json.array! [:once] do
        json.attachment do
          json.content_type "image/tiff"
          json.data @doc

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