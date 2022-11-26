json.careTeamEntriesList do
  json.array! @responses do |response|
    json.resource_count response[:count_summary] unless response[:count_summary].nil?
    json.careTeamEntries response[:resources].entries do |careTeam|

      careTeam = OpenStruct.new(careTeam)
      patient = OpenStruct.new(careTeam.patient)
      business_entity = OpenStruct.new(careTeam.business_entity)
      provider = OpenStruct.new(careTeam.provider)

      json.careTeam do
        json.account_number patient.external_id
        json.mrn patient.chart_number
        json.patient_name patient.full_name
        json.identifier careTeam.id
        json.text "Care Team"
        json.text_status "generated"
        json.status status_by_dates(careTeam.effective_from, careTeam.effective_end)
        json.period_start careTeam.effective_from
        json.period_end careTeam.effective_end

        json.participant do
          json.array!([:once]) do
            role = participant_role(careTeam['member_type'])
            json.role do
              json.coding do
                json.array!([:once]) do
                  if role == 'Physician'
                    json.code '158965000'
                    json.code_system 'snomed'
                    json.code_display 'Medical Practicioner'
                  else
                    json.code '116154003'
                    json.code_system 'snomed'
                    json.code_display 'Patient'
                  end
                end
              end
              if role == 'Physician'
                json.text 'Medical Practicioner'
              else
                json.text 'Patient'
              end

            end
            json.member do
              if role == 'Physician'
                json.reference "Practitioner/#{careTeam['member_id']}"
                json.display careTeam['member_full_name']
              else
                json.reference "Patient/#{patient.external_id}"
                json.display patient.full_name
              end
            end
          end
        end

        json.healthcare_entity do
          json.partial! :healthcare_entity, healthcare_entity: business_entity
        end
      end

      if @include_provenance_target
        json.partial! :_provenance, patient: patient, record: careTeam,
                      provider: provider, business_entity: business_entity,
                      obj: 'CareTeam'
      end
    end
  end
end
