# NOTE: this is how can we get access to the results section
# ['ClinicalDocument']['component']['structuredBody']['component']['section']

# section structure:
# - code {}
# - title
# - entry []

class ResultSection
  attr_accessor :title, :code, :entries
  attr_reader :table_data

  def initialize(raw_section)
    @title = raw_section['title']
    @code = OpenStruct.new(raw_section['code'])
    @table_data = parse_data_from_table(raw_section['text']['table'])
    @entries = parse_raw_entries(raw_section['entry'])
  end

  private

  def parse_data_from_table(table)
    trows = table['tbody']['tr']
    Array.wrap(trows).map do |tr|
      {
        title: extract_content_value(tr['td'][0]),
        date: extract_content_value(tr['td'][1]),
        measure: extract_content_value(tr['td'][2]),
        unit: extract_content_value(tr['td'][3]),
        abnormal_flag: extract_content_value(tr['td'][4]),
        location: extract_content_value(tr['td'][5])
      }
    end
  end

  def extract_content_value(td_obj)
    td_obj['content'] if td_obj && td_obj['content'].is_a?(String)
  end

  # NOTE: title and date depend on the title_and_dates index. It needs to be improved.
  # we could add this information into the xml file.
  def parse_raw_entries(raw_entries)
    Array.wrap(raw_entries).map.with_index do |entry, i|
      entry_value = entry.values.last
      OpenStruct.new({
        title: table_data[i][:title],
        start_date: table_data[i][:date],
        code: OpenStruct.new(entry_value['code']),
        status: entry_value['statusCode']['code'],
        measure_value: table_data[i][:measure],
        measure_unit: table_data[i][:unit],
        location: table_data[i][:location]
      })
    end
  end
end
