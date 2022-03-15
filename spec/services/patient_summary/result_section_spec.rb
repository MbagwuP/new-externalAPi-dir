require 'spec_helper'

describe "ResultSection" do
  let(:clinical_document_json) { # it represents the response body from ccda endpoint.
    file = File.read(File.join(APP_ROOT, '/spec/ccda_lab_result_example.json'))
    JSON.parse(file) 
  }

  let(:result_section_section) { clinical_document_json['ClinicalDocument']['component']['structuredBody']['component']['section'] }
  let(:result_section_title) { "Results" }
  let(:result_section_code_code) { "30954-2" }

  it 'is instantiated successfully' do
    result_section = ResultSection.new(result_section_section)
    expect(result_section).to be_a ResultSection
    expect(result_section.entries).to be_a Array
    expect(result_section.table_data).to be_a Array
    expect(result_section.title).to eq(result_section_title)
    expect(result_section.code.code).to eq(result_section_code_code)

  end
end
