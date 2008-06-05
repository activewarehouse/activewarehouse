require File.dirname(__FILE__) + '/test_helper'

class ScdTest < Test::Unit::TestCase
  def setup
    @connection = ETL::Engine.connection(:data_warehouse)
    @connection.delete("DELETE FROM person_dimension")
    
    @end_of_time = DateTime.parse('9999-12-31 00:00:00')
  end
  
  def test_type_1_run_1_inserts_record
    do_type_1_run(1)
    assert_equal 1, count_bobs
  end
  
  def test_type_1_run_1_sets_original_address
    do_type_1_run(1)
    assert_boston_address(find_bobs.first)
  end
  
  def test_type_1_run_1_sets_original_id
    do_type_1_run(1)
    assert_equal 1, find_bobs.first.id
  end
  
  def test_type_1_run_1_stores_crc
    do_type_1_run(1)
    assert_equal 1, type_1_crc_records.size
  end
  
  def test_type_1_run_2_deletes_old_record
    do_type_1_run(1)
    do_type_1_run(2)
    assert_equal 1, count_bobs, "new record created, but old not deleted: #{find_bobs.inspect}"
  end
  
  def test_type_1_run_2_updates_address
    do_type_1_run(1)
    do_type_1_run(2)
    
    assert_los_angeles_address(find_bobs.last)
  end
  
  def test_type_1_run_2_keeps_id
    do_type_1_run(1)
    do_type_1_run(2)
    assert_equal 1, find_bobs.first.id
  end
  
  def test_type_1_run_2_doesnt_create_extra_crc_record
    do_type_1_run(1)
    do_type_1_run(2)
    assert_equal 1, type_1_crc_records.size
  end
  
  def test_type_1_no_change_skips_load
    do_type_1_run(1)
    do_type_1_run(1)
    lines = lines_for('scd_test_type_1.txt')
    assert lines.empty?, "scheduled load expected to be empty, was #{lines.size} records"
  end
  
  def test_type_1_change_once_only_loaded_once
    do_type_1_run(1)
    do_type_1_run(2)
    do_type_1_run(2)
    assert_equal 1, count_bobs
    lines = lines_for('scd_test_type_1.txt')
    assert lines.empty?, "scheduled load expected to be empty, was #{lines.size} records"
  end
  
  def test_type_1_revert_udpates_address_on_new_record
    do_type_1_run(1)
    do_type_1_run(2)
    do_type_1_run(1)
    assert_boston_address(find_bobs.first)
  end
  
  def test_type_1_revert_keeps_record
    do_type_1_run(1)
    do_type_1_run(2)
    do_type_1_run(1)
    assert_equal 1, count_bobs
  end
  
  def test_type_2_run_1_inserts_record
    do_type_2_run(1)
    assert_equal 1, count_bobs
  end
  
  def test_type_2_run_1_sets_original_address
    do_type_2_run(1)
    assert_boston_address(find_bobs.first)
  end
  
  def test_type_2_run_1_sets_original_id
    do_type_2_run(1)
    assert_equal 1, find_bobs.first.id
  end
  
  def test_type_2_run_1_sets_effective_date
    do_type_2_run(1)
    # TODO: This is a test bug - if the tests don't run at the correct
    # time, this timestamp may not match the timestamp used during the
    # creation of the SCD row
    assert_equal current_datetime, find_bobs.first.effective_date, "failure might be a test bug - see test notes"
  end
  
  def test_type_2_run_1_sets_end_date
    do_type_2_run(1)
    assert_equal @end_of_time, find_bobs.first.end_date
  end
  
  def test_type_2_run_1_sets_latest_version
    do_type_2_run(1)
    assert find_bobs.first.latest_version?
  end
  
  def test_type_2_run_1_stores_crc
    do_type_2_run(1)
    assert_equal 1, type_2_crc_records.size
  end
  
  def test_type_2_run_2_inserts_new_record
    do_type_2_run(1)
    do_type_2_run(2)
    assert_equal 2, count_bobs
  end
  
  def test_type_2_run_2_keeps_primary_key_of_original_version
    do_type_2_run(1)
    do_type_2_run(2)
    assert_not_nil find_bobs.detect { |bob| 1 == bob.id }
  end
  
  def test_type_2_run_2_increments_primary_key_for_new_version
    do_type_2_run(1)
    do_type_2_run(2)
    assert_not_nil find_bobs.detect { |bob| 2 == bob.id }
  end
  
  def test_type_2_run_2_expires_old_record
    do_type_2_run(1)
    do_type_2_run(2)

    original_bob = find_bobs.detect { |bob| 1 == bob.id }
    new_bob = find_bobs.detect { |bob| 2 == bob.id }
    assert_equal new_bob.effective_date, original_bob.end_date
  end
  
  def test_type_2_run_2_keeps_address_for_expired_record
    do_type_2_run(1)
    do_type_2_run(2)

    assert_boston_address(find_bobs.detect { |bob| 1 == bob.id })
  end
  
  def test_type_2_run_2_updates_address_on_new_record    
    do_type_2_run(1)
    do_type_2_run(2)

    assert_los_angeles_address(find_bobs.detect { |bob| 2 == bob.id })
  end
  
  def test_type_2_run_2_activates_new_record
    do_type_2_run(1)
    do_type_2_run(2)

    # TODO: This is a test bug - if the tests don't run at the correct
    # time, this timestamp may not match the timestamp used during the
    # creation of the SCD row
    assert_equal current_datetime, find_bobs.detect { |bob| 2 == bob.id }.effective_date, "failure might be a test bug - see test notes"    
  end
  
  def test_type_2_run_2_sets_end_date_for_new_record
    do_type_2_run(1)
    do_type_2_run(2)
    assert_equal @end_of_time, find_bobs.detect { |bob| 2 == bob.id }.end_date
  end
  
  def test_type_2_run_2_shifts_latest_version
    do_type_2_run(1)
    do_type_2_run(2)

    original_bob = find_bobs.detect { |bob| 1 == bob.id }
    new_bob = find_bobs.detect { |bob| 2 == bob.id }
    assert !original_bob.latest_version?
    assert new_bob.latest_version?
  end
  
  def test_type_2_run_2_doesnt_create_extra_crc_record
    do_type_2_run(1)
    do_type_2_run(2)
    assert_equal 1, type_2_crc_records.size
  end
  
  
  def test_type_2_no_change_skips_load
    do_type_2_run(1)
    do_type_2_run(1)
    lines = lines_for('scd_test_type_2.txt')
    assert lines.empty?, "scheduled load expected to be empty, was #{lines.size} records"
  end
  
  def test_type_2_change_once_only_loaded_once
    do_type_2_run(1)
    do_type_2_run(2)
    do_type_2_run(2)
    assert_equal 2, count_bobs
    lines = lines_for('scd_test_type_2.txt')
    assert lines.empty?, "scheduled load expected to be empty, was #{lines.size} records"
  end
  
  def test_type_2_revert_inserts_new_record
    do_type_2_run(1)
    do_type_2_run(2)
    do_type_2_run(1)
    assert_equal 3, count_bobs
  end
  
  def test_type_2_revert_udpates_address_on_new_record
    do_type_2_run(1)
    do_type_2_run(2)
    do_type_2_run(1)
    assert_boston_address(find_bobs.detect { |bob| 3 == bob.id })
  end
  
  def test_type_2_scd_change_deletes_only_one_row
    do_type_2_run(1) # put first version in
    do_type_2_run(2) # put second version in
    # Two records right now
    assert_equal 2, count_bobs
    do_type_2_run(1) # put third version in (same as first version, but that's irrelevant)
    # was failing because first and second versions were being deleted.
    assert_equal 3, count_bobs
  end
  
  def test_type_2_non_scd_field_changes_dont_create_extra_record
    do_type_2_run_with_only_city_state_zip_scd(1)
    do_type_2_run_with_only_city_state_zip_scd(2)
    do_type_2_run_with_only_city_state_zip_scd(3)
    assert_equal 2, count_bobs
  end
  
  def test_type_2_non_scd_field_changes_keep_id
    do_type_2_run_with_only_city_state_zip_scd(1)
    do_type_2_run_with_only_city_state_zip_scd(2)
    do_type_2_run_with_only_city_state_zip_scd(3)
    
    assert_not_nil find_bobs.detect { |bob| 2 == bob.id }
  end
  
  def test_type_2_non_scd_field_changes_keep_dates
    do_type_2_run_with_only_city_state_zip_scd(1)
    do_type_2_run_with_only_city_state_zip_scd(2)
    old_bob = find_bobs.detect { |bob| 2 == bob.id }

    do_type_2_run_with_only_city_state_zip_scd(3)
    new_bob = find_bobs.detect { |bob| 2 == bob.id }
    
    assert_equal old_bob.end_date, new_bob.end_date
    assert_equal old_bob.effective_date, new_bob.effective_date
  end
  
  def test_type_2_non_scd_field_changes_keep_latest_version
    do_type_2_run_with_only_city_state_zip_scd(1)
    do_type_2_run_with_only_city_state_zip_scd(2)
    do_type_2_run_with_only_city_state_zip_scd(3)
    
    assert find_bobs.detect { |bob| 2 == bob.id }.latest_version?
  end
  
  def test_type_2_non_scd_fields_treated_like_type_1_fields
    do_type_2_run_with_only_city_state_zip_scd(1)
    do_type_2_run_with_only_city_state_zip_scd(2)
    do_type_2_run_with_only_city_state_zip_scd(3)
    assert_los_angeles_address(find_bobs.detect { |bob| 2 == bob.id }, "280 Pine Street")
  end
  
  def test_type_2_no_change_to_non_scd_fields_skips_load
    do_type_2_run_with_only_city_state_zip_scd(1)
    do_type_2_run_with_only_city_state_zip_scd(2)
    do_type_2_run_with_only_city_state_zip_scd(2)
    lines = lines_for('scd_test_type_2.txt')
    assert lines.empty?, "scheduled load expected to be empty, was #{lines.size} records"
  end  
  
  def do_type_2_run(run_num)
    ENV['run_number'] = run_num.to_s
    assert_nothing_raised do
      run_ctl_file("scd_test_type_2.ctl")
    end
  end
  
  def do_type_2_run_with_only_city_state_zip_scd(run_num)
    ENV['type_2_scd_fields'] = Marshal.dump([:city, :state, :zip_code])
    do_type_2_run(run_num)
  end
  
  def do_type_1_run(run_num)
    ENV['run_number'] = run_num.to_s
    assert_nothing_raised do
      run_ctl_file("scd_test_type_1.ctl")
    end
  end
  
  def lines_for(file)
    File.readlines(File.dirname(__FILE__) + "/output/#{file}")
  end
  
  def run_ctl_file(file)
    ETL::Engine.process(File.dirname(__FILE__) + "/#{file}")
  end
  
  def count_bobs
    @connection.select_value(
      "SELECT count(*) FROM person_dimension WHERE first_name = 'Bob' and last_name = 'Smith'").to_i
  end
  
  def find_bobs
    bobs = @connection.select_all(
      "SELECT * FROM person_dimension WHERE first_name = 'Bob' and last_name = 'Smith'")
    bobs.each do |bob|
      def bob.id
        self["id"].to_i
      end
      def bob.effective_date
        DateTime.parse(self["effective_date"])
      end
      def bob.end_date
        DateTime.parse(self["end_date"])
      end
      def bob.latest_version?
        ActiveRecord::ConnectionAdapters::Column.value_to_boolean(self["latest_version"])
      end
    end
    bobs
  end
  
  def current_datetime
    DateTime.parse(Time.now.to_s(:db))
  end
  
  def type_1_crc_records
    ETL::Execution::Record.find_all_by_control_file_and_natural_key(File.dirname(__FILE__) + "/scd_test_type_1.ctl", "Bob|Smith")
  end
  
  def type_2_crc_records
    ETL::Execution::Record.find_all_by_control_file_and_natural_key(File.dirname(__FILE__) + "/scd_test_type_2.ctl", "Bob|Smith")
  end
  
  def assert_boston_address(bob, street = "200 South Drive")
    assert_equal street, bob['address'], bob.inspect
    assert_equal "Boston", bob['city'], bob.inspect
    assert_equal "MA", bob['state'], bob.inspect
    assert_equal "32123", bob['zip_code'], bob.inspect
  end
  
  def assert_los_angeles_address(bob, street = "1010 SW 23rd St")
    assert_equal street, bob['address'], bob.inspect
    assert_equal "Los Angeles", bob['city'], bob.inspect
    assert_equal "CA", bob['state'], bob.inspect
    assert_equal "90392", bob['zip_code'], bob.inspect
  end
end