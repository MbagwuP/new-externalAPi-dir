require 'spec_helper'

describe "GoalSection" do
  let(:clinical_document_json) { # it represents the response body from ccda endpoint.
    file = File.read(File.join(APP_ROOT, '/spec/ccda_goal_example.json'))
    JSON.parse(file) 
  }

  let(:goal_section) { clinical_document_json['ClinicalDocument']['component']['structuredBody']['component']['section'] }
  let(:goal_title) { "Goals Section" }
  let(:goal_code_code) { "61146-7" }
  let(:title_and_dates) { [{title: " goal test", date: "02/23/2022" }] }

  it 'is instantiated successfully' do
    goal = GoalSection.new(goal_section)
    expect(goal).to be_a GoalSection
    expect(goal.entries).to be_a Array
    expect(goal.title_and_date).to be_a Array
    expect(goal.title).to eq(goal_title)
    expect(goal.code.code).to eq(goal_code_code)

    expect(goal.title_and_date).to eq(title_and_dates)
    expect(goal.entries.first.title).to eq(title_and_dates[0][:title])
  end
end
