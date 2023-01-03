# NOTE: this is how can we get access to the plan of treatment section
# ['ClinicalDocument']['component']['structuredBody']['component']['section']

# section structure:
# - code {}
# - title
# - entry []

class PlanOfTreatmentSection
  attr_accessor :title, :code, :entries
  attr_reader :entry_dates

  def initialize(raw_section)
    @raw_section = raw_section
    @title = raw_section['title'] || ''
    @code = OpenStruct.new(raw_section['code'])
    @entry_dates = parse_dates_from_table(raw_section['text']['table'])
    @entries = parse_raw_entries(raw_section['entry'])
  end

  private

  def parse_dates_from_table(table)
    trows = table['tbody']['tr']
    Array.wrap(trows).map do |tr|
      unless tr['td'][0].nil?
        Date.strptime(tr['td'][0].to_s,"%m/%d/%Y").to_time || tr['td'][0]
      else
        Date.strptime("02/03/2020","%m/%d/%Y").to_time
      end
    end
  end

  # NOTE: start_date depends on the dates index. It needs to be improved.
  # we need to add the date into entryRelationship on the xml doc.
  def parse_raw_entries(raw_entries)
    Array.wrap(raw_entries).map.with_index do |entry, i|
      entry_value = entry.values.first
      entry = build_entry_relationship_object(entry_value)
      entry.start_date = entry_dates[i]
      entry
    end
  end

  def build_entry_relationship_object(entry_value)
      entry_relationship_values = entry_value['entryRelationship']['act']
      code_object = OpenStruct.new(entry_relationship_values['code'])
      OpenStruct.new({
        title: entry_relationship_values['text'],
        code: code_object,
        status: entry_relationship_values['statusCode']['code']
      })
  end
end
