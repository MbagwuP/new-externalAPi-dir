# NOTE: this is how can we get access to the goal section
# ['ClinicalDocument']['component']['structuredBody']['component']['section']

# section structure:
# - code {}
# - title
# - entry []

class GoalSection
  attr_accessor :title, :code, :entries
  attr_reader :title_and_date

  def initialize(raw_section)
    @title = raw_section['title']
    @code = OpenStruct.new(raw_section['code'])
    @title_and_date = parse_title_and_date_from_table(raw_section['text']['table'])
    @entries = parse_raw_entries(raw_section['entry'])
  end

  private

  def parse_title_and_date_from_table(table)
    trows = table['tbody']['tr']
    Array.wrap(trows).map do |tr|
      {
        title: tr['td'][0],
        date: tr['td'][1],
        date_to: tr['td'][2],
        id: tr['td'][3]
      }
    end
  end

  # NOTE: title and date depend on the title_and_dates index. It needs to be improved.
  # we could add this information into the xml file.
  def parse_raw_entries(raw_entries)
    Array.wrap(raw_entries).map.with_index do |entry, i|
      entry_value = entry.values.first

      OpenStruct.new({
        title: title_and_date[i][:title],
        start_date: title_and_date[i][:date],
        target_date: title_and_date[i][:date_to],
        id: title_and_date[i][:id],
        code: OpenStruct.new(entry_value['code']),
        status: entry_value['statusCode']['code']
      })
    end
  end
end
