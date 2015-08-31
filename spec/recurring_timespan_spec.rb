require_relative 'spec_helper'

describe "RecurringTimespan" do

  let(:filter_dates_dst) {['2014-06-01', '2015-07-01']}
  let(:filter_dates_nodst) {['2015-01-01', '2015-02-10']}
  let(:filter_dates_overlap_into_dst) {['2015-02-03', '2015-03-20']}
  let(:filter_dates_overlap_outof_dst) {['2014-09-28', '2015-11-15']}

  # with these, I'm just including the timezone_offset here in the test,
  # they're not actually used in any of the logic and can be ignored
  let(:days_of_week_monday_and_wednesday) {{
    use_sunday: false,
    use_monday: true,
    use_tuesday: false,
    use_wednesday: true,
    use_thursday: false,
    use_friday: false,
    use_saturday: false
  }}
  let(:times_templates_eastern) {{
    effective_from: "2014-09-24T00:00:00-04:00",
    effective_to: nil,
    start_at: "2014-09-24T14:00:00-04:00",
    end_at: "2014-09-24T19:00:00-04:00",
    timezone_offset: "-05:00:00",
    timezone_name: "Eastern Time (US & Canada)"
  }}
  let(:times_templates_pacific) {{
    effective_from: "2014-09-24T00:00:00-07:00",
    effective_to: nil,
    start_at: "2014-09-24T12:00:00-07:00",
    end_at: "2014-09-24T13:15:00-07:00",
    timezone_offset: "-08:00:00",
    timezone_name: "Pacific Time (US & Canada)"
  }}
  let(:times_blockouts_eastern) {{
    effective_from: "2014-05-15T00:00:00-04:00",
    effective_to: nil,
    start_hour: 12,
    end_hour: 13,
    timezone_offset: "-05:00:00",
    timezone_name: "Eastern Time (US & Canada)"
  }}
  let(:times_blockouts_pacific) {{
    effective_from: "2014-05-15T00:00:00-07:00",
    effective_to: nil,
    start_hour: 8,
    end_hour: 10,
    timezone_offset: "-08:00:00",
    timezone_name: "Pacific Time (US & Canada)"
  }}
  let(:times_blockouts_eastern_endofday_starthour) {{
    effective_from: "2014-05-15T00:00:00-04:00",
    effective_to: nil,
    start_hour: 24,
    end_hour: 29,
    timezone_offset: "-05:00:00",
    timezone_name: "Eastern Time (US & Canada)"
  }}
  let(:times_blockouts_eastern_endofday_endhour) {{
    effective_from: "2014-05-15T00:00:00-04:00",
    effective_to: nil,
    start_hour: 0,
    end_hour: 24,
    timezone_offset: "-05:00:00",
    timezone_name: "Eastern Time (US & Canada)"
  }}
  let(:times_blockouts_pacific_endofday_starthour) {{
    effective_from: "2014-05-15T00:00:00-04:00",
    effective_to: nil,
    start_hour: 24,
    end_hour: 29,
    timezone_offset: "-08:00:00",
    timezone_name: "Pacific Time (US & Canada)"
  }}
  let(:times_blockouts_pacific_endofday_endhour) {{
    effective_from: "2014-05-15T00:00:00-04:00",
    effective_to: nil,
    start_hour: 0,
    end_hour: 24,
    timezone_offset: "-08:00:00",
    timezone_name: "Pacific Time (US & Canada)"
  }}
  let(:recurring_timespan) { RecurringTimespan.new input_hash }
  let(:eastern_to_practice_hour_difference) { recurring_timespan.send(:eastern_to_practice_hour_difference) }
  let(:occurences) { recurring_timespan.occurences_in_date_range(*filter_dates) }

  shared_examples 'general timespan behavior' do
    it 'stores effective dates as instances of Date if they are present' do
      effective_from = recurring_timespan.instance_variable_get(:@effective_from)
      effective_to = recurring_timespan.instance_variable_get(:@effective_to)

      expect(effective_from.is_a?(Date) || effective_from.nil?).to be_true
      expect(effective_to.is_a?(Date) || effective_to.nil?).to be_true
    end

    it "stores start/end times as instances of Time" do
      effective_from = recurring_timespan.instance_variable_get(:@start_at)
      effective_to = recurring_timespan.instance_variable_get(:@end_at)

      expect(effective_from.is_a?(Time)).to be_true
      expect(effective_to.is_a?(Time)).to be_true
    end

    it "has consistent hour fields for each occurence's timestamp" do
      same_start_hour = occurences.map{|x| x[:start_at][11..12].to_i }.uniq.length == 1
      same_end_hour = occurences.map{|x| x[:end_at][11..12].to_i }.uniq.length == 1
      expect(same_start_hour).to be_true
      expect(same_end_hour).to be_true
    end


    # it "has occurences with hours equal to the originally passed in hours with the difference between Eastern and Practice time applied" do
    # it "has occurences with hours equal to the hours stored in the Practice's local time" do

    it "has occurences with hours that are correct with regard to the difference between Eastern time and Practice time OR end of day time" do
      if input_hash[:start_hour]
        original_json_start_hour = input_hash[:start_hour].to_i
        original_json_end_hour = input_hash[:end_hour].to_i
      else
        original_json_start_hour = input_hash[:start_at][11..12].to_i
        original_json_end_hour = input_hash[:end_at][11..12].to_i
      end

      original_parsed_start_hour_eastern = recurring_timespan.instance_variable_get(:@start_hour_eastern)
      original_parsed_end_hour_eastern = recurring_timespan.instance_variable_get(:@end_hour_eastern)
      original_parsed_start_hour = recurring_timespan.instance_variable_get(:@start_hour)
      original_parsed_end_hour = recurring_timespan.instance_variable_get(:@end_hour)

      start_hour_first_occurence = occurences.map{|x| x[:start_at][11..12].to_i }.first
      start_hour_last_occurence = occurences.map{|x| x[:start_at][11..12].to_i }.last
      end_hour_first_occurence = occurences.map{|x| x[:end_at][11..12].to_i }.first
      end_hour_last_occurence = occurences.map{|x| x[:end_at][11..12].to_i }.last

      if original_json_start_hour <= 23
        original_json_start_hour.should == original_parsed_start_hour_eastern
        original_parsed_start_hour.should == original_parsed_start_hour_eastern + eastern_to_practice_hour_difference
      else
        # we'll be ignoring these fields and hard setting it to 23:59:59, so just make sure that flag is set to true
        recurring_timespan.instance_variable_get(:@start_at_end_of_day)
      end
      if original_json_end_hour <= 23
        original_json_end_hour.should == original_parsed_end_hour_eastern
        original_parsed_end_hour.should == original_parsed_end_hour_eastern + eastern_to_practice_hour_difference
      else
        # we'll be ignoring these fields and hard setting it to 23:59:59, so just make sure that flag is set to true
        recurring_timespan.instance_variable_get(:@end_at_end_of_day)
      end

      if original_json_start_hour <= 23
        start_hour_first_occurence.should == original_parsed_start_hour_eastern + eastern_to_practice_hour_difference
        start_hour_first_occurence.should == original_parsed_start_hour
      else
        start_hour_first_occurence.should == 23
      end

      if original_json_end_hour <= 23
        end_hour_first_occurence.should == original_parsed_end_hour_eastern + eastern_to_practice_hour_difference
        end_hour_first_occurence.should == original_parsed_end_hour
      else
        end_hour_first_occurence.should == 23
      end

      if original_json_start_hour <= 23
        start_hour_last_occurence.should == original_parsed_start_hour_eastern + eastern_to_practice_hour_difference
        start_hour_last_occurence.should == original_parsed_start_hour
      else
        start_hour_last_occurence.should == 23
      end

      if original_json_end_hour <= 23
        end_hour_last_occurence.should == original_parsed_end_hour_eastern + eastern_to_practice_hour_difference
        end_hour_last_occurence.should == original_parsed_end_hour
      else
        end_hour_last_occurence.should == 23
      end
    end

    it "has correct timezone offsets depending on DST for that date" do
      first_occurence_start_at_offset = RecurringTimespan.iso8601_get_offset_as_integer(occurences.first[:start_at])
      last_occurence_start_at_offset = RecurringTimespan.iso8601_get_offset_as_integer(occurences.last[:start_at])
      timezone_offset_as_integer = recurring_timespan.send(:timezone_offset_as_integer)

      case example.metadata[:example_group][:description_args]
      when 'DST'
        first_occurence_start_at_offset.should == timezone_offset_as_integer + 1
        last_occurence_start_at_offset.should == timezone_offset_as_integer + 1
      when 'nonDST'
        first_occurence_start_at_offset.should == timezone_offset_as_integer
        last_occurence_start_at_offset.should == timezone_offset_as_integer
      when 'overlapping nonDST into DST'
        first_occurence_start_at_offset.should == timezone_offset_as_integer
        last_occurence_start_at_offset.should == timezone_offset_as_integer + 1
      when 'overlapping DST into nonDST'
        first_occurence_start_at_offset.should == timezone_offset_as_integer + 1
        last_occurence_start_at_offset.should == timezone_offset_as_integer
      end
    end
  end

  context "with TIMESTAMP TIME FIELDS" do
    shared_examples 'timestamp timefields behavior' do
      it "stores start and end hours in Eastern Time that are derived from the timestamp" do
      # it "stores start_hours and end_hours derived from the timestamp fields with consideration for the difference between Eastern Time and Practice time applied" do
        original_start_hour = input_hash[:start_at][11..12]
        original_end_hour = input_hash[:end_at][11..12]
        stored_start_hour_eastern = recurring_timespan.instance_variable_get(:@start_hour_eastern)
        stored_end_hour_eastern = recurring_timespan.instance_variable_get(:@end_hour_eastern)

        original_start_hour.to_i.should == stored_start_hour_eastern
        original_end_hour.to_i.should == stored_end_hour_eastern
      end

      it "stores start and end hours in Practice Time by applying the difference between the Practice's timezone and Eastern Time" do
        stored_start_hour = recurring_timespan.instance_variable_get(:@start_hour)
        stored_end_hour = recurring_timespan.instance_variable_get(:@end_hour)
        stored_start_hour_eastern = recurring_timespan.instance_variable_get(:@start_hour_eastern)
        stored_end_hour_eastern = recurring_timespan.instance_variable_get(:@end_hour_eastern)

        stored_start_hour.to_i.should == stored_start_hour_eastern + eastern_to_practice_hour_difference
        stored_end_hour.to_i.should == stored_end_hour_eastern + eastern_to_practice_hour_difference
      end
    end

    context 'Eastern Time' do
      let(:input_hash) { days_of_week_monday_and_wednesday.merge(times_templates_eastern) }

      context 'DST' do
        let(:filter_dates) { filter_dates_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'timestamp timefields behavior'
      end

      context 'non DST' do
        let(:filter_dates) { filter_dates_nodst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'timestamp timefields behavior'
      end

      context 'overlapping nonDST into DST' do
        let(:filter_dates) { filter_dates_overlap_into_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'timestamp timefields behavior'
      end

      context 'overlapping DST into nonDST' do
        let(:filter_dates) { filter_dates_overlap_outof_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'timestamp timefields behavior'
      end
    end

    context 'Pacific Time' do
      let(:input_hash) { days_of_week_monday_and_wednesday.merge(times_templates_pacific) }

      context 'DST' do
        let(:filter_dates) { filter_dates_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'timestamp timefields behavior'
      end

      context 'non DST' do
        let(:filter_dates) { filter_dates_nodst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'timestamp timefields behavior'
      end

      context 'overlapping nonDST into DST' do
        let(:filter_dates) { filter_dates_overlap_into_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'timestamp timefields behavior'
      end

      context 'overlapping DST into nonDST' do
        let(:filter_dates) { filter_dates_overlap_outof_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'timestamp timefields behavior'
      end
    end
  end

  context "with INTEGER TIME FIELDS" do

    shared_examples 'integer timefields behavior' do
      it "has occurences with hours that correctly reflect the integer hours that were passed in, with the difference between Eastern time and Practice time applied" do
        original_start_hour = input_hash[:start_hour]
        original_end_hour = input_hash[:end_hour]
        start_hour_first_occurence = occurences.map{|x| x[:start_at][11..12].to_i }.first
        start_hour_last_occurence = occurences.map{|x| x[:start_at][11..12].to_i }.last

        end_hour_first_occurence = occurences.map{|x| x[:end_at][11..12].to_i }.first
        end_hour_last_occurence = occurences.map{|x| x[:end_at][11..12].to_i }.last

        if original_start_hour <= 23
          start_hour_first_occurence.should == original_start_hour + eastern_to_practice_hour_difference
          start_hour_last_occurence.should == original_start_hour + eastern_to_practice_hour_difference
        else
          start_hour_first_occurence.should == 23
          start_hour_last_occurence.should == 23
        end

        if original_end_hour <= 23
          end_hour_first_occurence.should == original_end_hour + eastern_to_practice_hour_difference
          end_hour_last_occurence.should == original_end_hour + eastern_to_practice_hour_difference
        else
          end_hour_first_occurence.should == 23
          end_hour_last_occurence.should == 23
        end
      end
    end

    shared_examples 'end of day start hour behavior' do
      it "has occurences with starting hours of 23" do
        start_hour_first_occurence = occurences.map{|x| x[:start_at][11..12].to_i }.first
        start_hour_last_occurence = occurences.map{|x| x[:start_at][11..12].to_i }.last

        start_hour_first_occurence.should == 23
        start_hour_last_occurence.should == 23
      end

      it "it has occurences with starting minutes of 59" do
        start_minutes_first_occurence = occurences.map{|x| x[:start_at][14..15].to_i }.first
        start_minutes_last_occurence = occurences.map{|x| x[:start_at][14..15].to_i }.last

        start_minutes_first_occurence.should == 59
        start_minutes_last_occurence.should == 59
      end

      it "it has occurences with starting seconds of 59" do
        start_seconds_first_occurence = occurences.map{|x| x[:start_at][17..18].to_i }.first
        start_seconds_last_occurence = occurences.map{|x| x[:start_at][17..18].to_i }.last

        start_seconds_first_occurence.should == 59
        start_seconds_last_occurence.should == 59
      end
    end

    shared_examples 'end of day end hour behavior' do
      it "has occurences with ending hours of 23" do
        end_hour_first_occurence = occurences.map{|x| x[:end_at][11..12].to_i }.first
        end_hour_last_occurence = occurences.map{|x| x[:end_at][11..12].to_i }.last

        end_hour_first_occurence.should == 23
        end_hour_last_occurence.should == 23
      end

      it "it has occurences with ending minutes of 59" do
        end_minutes_first_occurence = occurences.map{|x| x[:end_at][14..15].to_i }.first
        end_minutes_last_occurence = occurences.map{|x| x[:end_at][14..15].to_i }.last

        end_minutes_first_occurence.should == 59
        end_minutes_last_occurence.should == 59
      end

      it "it has occurences with ending seconds of 59" do
        end_seconds_first_occurence = occurences.map{|x| x[:end_at][17..18].to_i }.first
        end_seconds_last_occurence = occurences.map{|x| x[:end_at][17..18].to_i }.last

        end_seconds_first_occurence.should == 59
        end_seconds_last_occurence.should == 59
      end
    end

    context 'Eastern Time' do
      let(:input_hash) { days_of_week_monday_and_wednesday.merge(times_blockouts_eastern) }

      context 'DST' do
        let(:filter_dates) { filter_dates_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
      end

      context 'non DST' do
        let(:filter_dates) { filter_dates_nodst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
      end

      context 'overlapping nonDST into DST' do
        let(:filter_dates) { filter_dates_overlap_into_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
      end

      context 'overlapping DST into nonDST' do
        let(:filter_dates) { filter_dates_overlap_outof_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
      end
    end

    context 'Pacific Time' do
      let(:input_hash) { days_of_week_monday_and_wednesday.merge(times_blockouts_pacific) }

      context 'DST' do
        let(:filter_dates) { filter_dates_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
      end

      context 'non DST' do
        let(:filter_dates) { filter_dates_nodst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
      end

      context 'overlapping nonDST into DST' do
        let(:filter_dates) { filter_dates_overlap_into_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
      end

      context 'overlapping DST into nonDST' do
        let(:filter_dates) { filter_dates_overlap_outof_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
      end
    end

    context 'Eastern Time with End Of Day start_hour (24)' do
      let(:input_hash) { days_of_week_monday_and_wednesday.merge(times_blockouts_eastern_endofday_starthour) }

      context 'DST' do
        let(:filter_dates) { filter_dates_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
        it_behaves_like 'end of day start hour behavior'
      end

      context 'non DST' do
        let(:filter_dates) { filter_dates_nodst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
        it_behaves_like 'end of day start hour behavior'
      end

      context 'overlapping nonDST into DST' do
        let(:filter_dates) { filter_dates_overlap_into_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
        it_behaves_like 'end of day start hour behavior'
      end

      context 'overlapping DST into nonDST' do
        let(:filter_dates) { filter_dates_overlap_outof_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
        it_behaves_like 'end of day start hour behavior'
      end
    end

    context 'Eastern Time with End Of Day end_hour (24)' do
      let(:input_hash) { days_of_week_monday_and_wednesday.merge(times_blockouts_eastern_endofday_endhour) }

      context 'DST' do
        let(:filter_dates) { filter_dates_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
        it_behaves_like 'end of day end hour behavior'
      end

      context 'non DST' do
        let(:filter_dates) { filter_dates_nodst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
        it_behaves_like 'end of day end hour behavior'
      end

      context 'overlapping nonDST into DST' do
        let(:filter_dates) { filter_dates_overlap_into_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
        it_behaves_like 'end of day end hour behavior'
      end

      context 'overlapping DST into nonDST' do
        let(:filter_dates) { filter_dates_overlap_outof_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
        it_behaves_like 'end of day end hour behavior'
      end
    end

    context 'Pacific Time with End Of Day start_hour (24)' do
      let(:input_hash) { days_of_week_monday_and_wednesday.merge(times_blockouts_pacific_endofday_starthour) }

      context 'DST' do
        let(:filter_dates) { filter_dates_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
        it_behaves_like 'end of day start hour behavior'
      end

      context 'non DST' do
        let(:filter_dates) { filter_dates_nodst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
        it_behaves_like 'end of day start hour behavior'
      end

      context 'overlapping nonDST into DST' do
        let(:filter_dates) { filter_dates_overlap_into_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
        it_behaves_like 'end of day start hour behavior'
      end

      context 'overlapping DST into nonDST' do
        let(:filter_dates) { filter_dates_overlap_outof_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
        it_behaves_like 'end of day start hour behavior'
      end
    end

    context 'Pacific Time with End Of Day end_hour (24)' do
      let(:input_hash) { days_of_week_monday_and_wednesday.merge(times_blockouts_pacific_endofday_endhour) }

      context 'DST' do
        let(:filter_dates) { filter_dates_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
        it_behaves_like 'end of day end hour behavior'
      end

      context 'non DST' do
        let(:filter_dates) { filter_dates_nodst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
        it_behaves_like 'end of day end hour behavior'
      end

      context 'overlapping nonDST into DST' do
        let(:filter_dates) { filter_dates_overlap_into_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
        it_behaves_like 'end of day end hour behavior'
      end

      context 'overlapping DST into nonDST' do
        let(:filter_dates) { filter_dates_overlap_outof_dst }
        it_behaves_like 'general timespan behavior'
        it_behaves_like 'integer timefields behavior'
        it_behaves_like 'end of day end hour behavior'
      end
    end

  end

end
