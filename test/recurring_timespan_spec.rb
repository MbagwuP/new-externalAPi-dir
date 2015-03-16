require_relative 'spec_helper'

# at some point here, compare .iso8601 on @start_ate to the timestamp input string

describe "RecurringTimespan" do

  shared_examples 'general timespan behavior' do

    it 'stores effective dates as instances of Date if they are present' do
      effective_from = recurring_timespan_templates.instance_variable_get(:@effective_from)
      effective_to = recurring_timespan_templates.instance_variable_get(:@effective_to)

      expect(effective_from.is_a?(Date) || effective_from.nil?).to be_true
      expect(effective_to.is_a?(Date) || effective_to.nil?).to be_true
    end

    it "stores start/end times as instances of Time" do
      effective_from = recurring_timespan_templates.instance_variable_get(:@start_at)
      effective_to = recurring_timespan_templates.instance_variable_get(:@end_at)

      expect(effective_from.is_a?(Time)).to be_true
      expect(effective_to.is_a?(Time)).to be_true
    end

    # it "returns occurences for a given date range" do
    #   occurences = recurring_timespan_templates.occurences_in_date_range('2015-01-03', '2015-02-10')
    #   rows_exist = occurences.any?
    #   all_occurences_are_correct_type = occurences.map{|x| x if !x[:start_at].is_a?(ActiveSupport::TimeWithZone) }.compact.empty?
    #
    #   # require 'pry'; binding.pry
    #   expect(rows_exist).to be_true
    #   expect(all_occurences_are_correct_type).to be_true
    # end

    it "returns occurences for the correct days of the week" do
    end

    it "has consistent hour fields for each occurence's timestamp" do
      occurences = recurring_timespan_templates.occurences_in_date_range('2015-02-03', '2015-03-20')
      same_start_hour = occurences.map{|x| x[:start_at][11..12].to_i }.uniq.length == 1
      same_end_hour = occurences.map{|x| x[:end_at][11..12].to_i }.uniq.length == 1
      expect(same_start_hour).to be_true
      expect(same_end_hour).to be_true
    end

    it "has occurences with hours that match the hours of the original start and end times" do
      occurences = recurring_timespan_templates.occurences_in_date_range('2015-02-03', '2015-03-20')

      if input_hash[:start_hour]
        original_json_start_hour = input_hash[:start_hour].to_i
        original_json_end_hour = input_hash[:end_hour].to_i
      else
        original_json_start_hour = input_hash[:start_at][11..12].to_i
        original_json_end_hour = input_hash[:start_at][11..12].to_i
      end

      original_parsed_start_hour = recurring_timespan_templates.instance_variable_get(:@start_hour) || recurring_timespan_templates.instance_variable_get(:@start_at).hour
      original_parsed_end_hour = recurring_timespan_templates.instance_variable_get(:@end_hour) || recurring_timespan_templates.instance_variable_get(:@end_at).hour

      start_hour_first_occurence = occurences.map{|x| x[:start_at][11..12].to_i }.first
      start_hour_last_occurence = occurences.map{|x| x[:start_at][11..12].to_i }.last
      end_hour_first_occurence = occurences.map{|x| x[:end_at][11..12].to_i }.first
      end_hour_last_occurence = occurences.map{|x| x[:end_at][11..12].to_i }.last

      original_json_start_hour.should == original_parsed_start_hour
      original_json_end_hour.should == original_json_end_hour

      start_hour_first_occurence.should == original_parsed_start_hour
      end_hour_first_occurence.should == original_parsed_end_hour

      start_hour_last_occurence.should == original_parsed_start_hour
      end_hour_last_occurence.should == original_parsed_end_hour
    end

    it "has correctly varying timezone offsets depending on DST for that date" do
    end


  end
  #
  #
  # context "start and end times provided as integers for the hour and minute" do
  #
  # end
  context "with TIMESTAMP TIME FIELDS" do
    # let(:input_json) { '{"business_entity_id":"84fca1d4-63b1-42f1-81cd-2f25db5a9a2b","created_at":"2014-05-14T10:56:32-04:00","created_by":28171,"description":null,"effective_from":"2014-05-15T00:00:00-04:00","effective_to":null,"end_hour":13,"end_hour_bak":null,"end_minutes":0,"id":293414,"name":"LUNCH","start_hour":12,"start_hour_bak":null,"start_minutes":15,"updated_at":"2014-05-14T10:56:32-04:00","updated_by":28171,"use_friday":true,"use_monday":true,"use_saturday":false,"use_sunday":false,"use_thursday":true,"use_tuesday":true,"use_wednesday":true,"timezone_offset":"-05:00:00","timezone_name":"Eastern Time (US & Canada)"}' }
    let(:input_json) { '{"id":54935,"name":"PHYSICALS","locations":[{"id":8296,"name":"TAMBERTEST"}],"resources":[{"id":5773,"name":"CLINIC ROOM 1"}],"visit_reasons":[{"id":21342,"name":"SYMPTOM ASSESSMENT","max_appointments_allowed":null}],"business_entity_id":"84fca1d4-63b1-42f1-81cd-2f25db5a9a2b","description":null,"use_monday":true,"use_tuesday":false,"use_wednesday":false,"use_thursday":false,"use_friday":false,"use_saturday":false,"use_sunday":false,"effective_from":"2014-09-24T00:00:00-04:00","effective_to":null,"max_appointments_allowed":1,"start_at":"2014-09-24T14:00:00-04:00","end_at":"2014-09-24T19:00:00-04:00","timezone_offset":"-05:00:00","timezone_name":"Eastern Time (US & Canada)"}' }
    let(:input_hash) { JSON.parse input_json }
    let(:recurring_timespan_templates) { RecurringTimespan.new input_hash }

    it_behaves_like 'general timespan behavior'

    it "matches the iso6801 format of the original start_time that was passed in" do
      original_8601 = input_hash['start_at']
      parsed_8601 = recurring_timespan_templates.instance_variable_get(:@start_at).iso8601
      original_8601.should == parsed_8601
    end
  end

  context "with INTEGER TIME FIELDS" do
    let(:input_json) { '{"business_entity_id":"84fca1d4-63b1-42f1-81cd-2f25db5a9a2b","created_at":"2014-05-14T10:56:32-04:00","created_by":28171,"description":null,"effective_from":"2014-05-15T00:00:00-04:00","effective_to":null,"end_hour":13,"end_hour_bak":null,"end_minutes":0,"id":293414,"name":"LUNCH","start_hour":12,"start_hour_bak":null,"start_minutes":15,"updated_at":"2014-05-14T10:56:32-04:00","updated_by":28171,"use_friday":true,"use_monday":true,"use_saturday":false,"use_sunday":false,"use_thursday":true,"use_tuesday":true,"use_wednesday":true,"timezone_offset":"-05:00:00","timezone_name":"Eastern Time (US & Canada)"}' }
    let(:input_hash) { JSON.parse input_json }
    let(:recurring_timespan_templates) { RecurringTimespan.new input_hash }

    it_behaves_like 'general timespan behavior'

    it "has occurences with hours that match the integer hours that were passed in" do
      occurences = recurring_timespan_templates.occurences_in_date_range('2015-02-03', '2015-03-20')

      original_start_hour = input_hash[:start_hour]
      original_end_hour = input_hash[:end_hour]
      start_hour_first_occurence = occurences.map{|x| x[:start_at][11..12].to_i }.first
      start_hour_last_occurence = occurences.map{|x| x[:start_at][11..12].to_i }.last

      end_hour_first_occurence = occurences.map{|x| x[:end_at][11..12].to_i }.first
      end_hour_last_occurence = occurences.map{|x| x[:end_at][11..12].to_i }.last

      start_hour_first_occurence.should == original_start_hour
      start_hour_last_occurence.should == original_start_hour

      end_hour_first_occurence.should == original_end_hour
      end_hour_last_occurence.should == original_end_hour
    end

  end

end
