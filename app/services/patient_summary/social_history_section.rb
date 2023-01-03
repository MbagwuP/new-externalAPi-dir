# NOTE: this is how can we get access to the social history section
# ['ClinicalDocument']['component']['structuredBody']['component']['section']

# section structure:
# - code {}
# - title
# - entry []

class SocialHistorySection
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
      td = tr['td']

      next unless td.length.eql?(3) # validate No Social History

      {
        description: extract_content_value(td[0]),
        quantity: td[1],
        date: td[2]
      }
    end.compact
  end

  def extract_content_value(td_obj)
    td_obj['content'] if td_obj && td_obj['content'].is_a?(String)
  end


  # NOTE: description, quantity and date depend on the table_data index. It needs to be improved.
  # we could add this information into the xml file.
  def parse_raw_entries(raw_entries)
    Array.wrap(raw_entries).map.with_index do |entry, i|
      entry_value = entry.values.last

      next unless table_data[i]

      OpenStruct.new({
        title: table_data[i][:quantity],
        description: table_data[i][:description],
        start_date: table_data[i][:date],
        code: OpenStruct.new(entry_value['code']),
        value_code: OpenStruct.new(entry_value['value']),
        status: entry_value['statusCode']['code']
      })
    end.compact
  end
end
