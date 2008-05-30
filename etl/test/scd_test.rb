require File.dirname(__FILE__) + '/test_helper'

class ScdTest < Test::Unit::TestCase
  def setup
    @connection = ETL::Engine.connection(:data_warehouse)
    @connection.delete("DELETE FROM person_dimension")
    
    @end_of_time = '9999-12-31 00:00:00'
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
    # TODO: make this pass
    # do_type_1_run(1)
    # do_type_1_run(2)
    # assert_equal 1, find_bobs.first.id
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
    assert_equal Time.now.to_s(:db), find_bobs.first.effective_date, "failure might be a test bug - see test notes"
  end
  
  def test_type_2_run_1_sets_end_date
    do_type_2_run(1)
    assert_equal @end_of_time, find_bobs.first.end_date
  end

  def test_type_2_run_2_inserts_new_record
    do_type_2_run(1)
    do_type_2_run(2)
    assert_equal 2, count_bobs
  end
  
  def test_type_2_run_2_keeps_id
    do_type_2_run(1)
    do_type_2_run(2)
    assert_equal [1, 2], find_bobs.map(&:id).sort
  end
  
  def test_type_2_run_2_expires_old_record
    do_type_2_run(1)
    do_type_2_run(2)

    # TODO: This is a test bug - if the tests don't run at the correct
    # time, this timestamp may not match the timestamp used during the
    # creation of the SCD row
    assert_equal Time.now.to_s(:db), find_bobs.detect { |bob| 1 == bob.id }.end_date, "failure might be a test bug - see test notes"
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
    assert_equal Time.now.to_s(:db), find_bobs.detect { |bob| 2 == bob.id }.effective_date, "failure might be a test bug - see test notes"    
  end
  
  def test_type_2_run_2_activates_sets_end_date_for_new_record
    do_type_2_run(1)
    do_type_2_run(2)
    assert_equal @end_of_time, find_bobs.detect { |bob| 2 == bob.id }.end_date
  end
  
  # # This should pass, but doesn't (b/c CRC isn't being saved?) (run outside of a job)
  # def test_type_2_scd_no_change_keeps_row
  #   do_type_2_run(1)
  #   do_type_2_run(1)
  #   assert_equal 1, count_bobs
  # end
  
  def test_type_2_scd_change_deletes_only_one_row
    do_type_2_run(1) # put first version in
    do_type_2_run(2) # put second version in
    # Two records right now
    assert_equal 2, count_bobs
    do_type_2_run(1) # put third version in (same as first version, but that's irrelevant)
    # was failing because first and second versions were being deleted.
    assert_equal 3, count_bobs
  end
  
  def do_type_2_run(run_num)
    ENV['run_number'] = run_num.to_s
    assert_nothing_raised do
      run_ctl_file("scd_test_type_2.ctl")
    end
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
        self["effective_date"]
      end
      def bob.end_date
        self["end_date"]
      end
    end
    bobs
  end
  
  def assert_boston_address(bob)
    assert_equal "200 South Drive", bob['address'], "expected Boston street: #{bob.inspect}"
    assert_equal "Boston", bob['city'], "expected Boston city: #{bob.inspect}"
    assert_equal "MA", bob['state'], "expected Boston state: #{bob.inspect}"
    assert_equal "32123", bob['zip_code'], "expected Boston zip: #{bob.inspect}"
  end
  
  def assert_los_angeles_address(bob)
    assert_equal "1010 SW 23rd St", bob['address'], "expected Los Angeles street: #{bob.inspect}"
    assert_equal "Los Angeles", bob['city'], "expected Los Angeles city: #{bob.inspect}"
    assert_equal "CA", bob['state'], "expected Los Angeles state: #{bob.inspect}"
    assert_equal "90392", bob['zip_code'], "expected Los Angeles zip: #{bob.inspect}"    
  end
end