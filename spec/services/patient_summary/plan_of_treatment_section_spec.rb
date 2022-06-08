require 'spec_helper'

describe "PlanOfTreatmentSection" do
  let(:clinical_document_json) { # it represents the response body from ccda endpoint.
    file = File.read(File.join(APP_ROOT, '/spec/ccda_plan_of_treatment_example.json'))
    JSON.parse(file) 
  }
  let(:plan_of_trearment_section) { clinical_document_json['ClinicalDocument']['component']['structuredBody']['component']['section'] }
  let(:plan_of_treatment_title) { "Plan of Treatment" }
  let(:plan_of_treatment_code_code) { "18776-5" }
  let(:dates) { ["08/20/2021", "11/12/2021", "12/20/2021", "12/20/2021", "11/30/2021", "11/30/2021"] }

  it 'is instantiated successfully' do
    plan_of_treatment = PlanOfTreatmentSection.new(plan_of_trearment_section)

    expect(plan_of_treatment).to be_a PlanOfTreatmentSection
    expect(plan_of_treatment.entries).to be_a Array
    expect(plan_of_treatment.entry_dates).to be_a Array
    expect(plan_of_treatment.title).to eq(plan_of_treatment_title)
    expect(plan_of_treatment.code.code).to eq(plan_of_treatment_code_code)
    expect(plan_of_treatment.entry_dates).to eq(dates)

    expect(plan_of_treatment.entries.first.start_date).to eq(dates[0])
    expect(plan_of_treatment.entries.last.start_date).to eq(dates[5])
  end
end
