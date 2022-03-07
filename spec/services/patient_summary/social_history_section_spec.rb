require 'spec_helper'

describe "SocialHistorySection" do
  let(:clinical_document_json) { # it represents the response body from ccda endpoint.
    file = File.read(File.join(APP_ROOT, '/spec/ccda_smoking_status_example.json'))
    JSON.parse(file) 
  }

  let(:social_history_section) { clinical_document_json['ClinicalDocument']['component']['structuredBody']['component']['section'] }
  let(:social_history_title) { "Social History" }
  let(:social_history_code_code) { "29762-2" }
  let(:table_data) { [{description: "Smoking Status", quantity: "never smoked", date: "08/21/2019" }] }

  it 'is instantiated successfully' do
    social_history = SocialHistorySection.new(social_history_section)
    expect(social_history).to be_a SocialHistorySection
    expect(social_history.entries).to be_a Array
    expect(social_history.table_data).to be_a Array
    expect(social_history.title).to eq(social_history_title)
    expect(social_history.code.code).to eq(social_history_code_code)
    expect(social_history.table_data).to eq(table_data)
  end
end
