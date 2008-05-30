require File.dirname(__FILE__) + '/test_helper'

class ScdTest < Test::Unit::TestCase
  def setup
    @connection = ETL::Engine.connection(:data_warehouse)
    @connection.delete("DELETE FROM person_dimension")
  end
  def test_type_1_scd_inserts_record
    do_type_1_run(1)
    # TODO: This is a test bug - if the tests don't run at the correct
    # time, this timestamp may not match the timestamp used during the
    # creation of the SCD row
    timestamp = Time.now
    
    lines = lines_for('scd_test_type_1.txt')
    assert_equal(
      "1,Bob,Smith,200 South Drive,Boston,MA,32123,#{timestamp.to_s(:db)},9999-12-31 00:00:00\n",
      lines.first
    )
  end
  
  def test_type_1_scd_inserts_updated_record
    do_type_1_run(2)
    # TODO: This is a test bug - if the tests don't run at the correct
    # time, this timestamp may not match the timestamp used during the
    # creation of the SCD row
    timestamp = Time.now
    
    lines = lines_for('scd_test_type_1.txt')
    assert_equal(
      "1,Bob,Smith,1010 SW 23rd St,Los Angeles,CA,90392,#{timestamp.to_s(:db)},9999-12-31 00:00:00\n",
      lines.first
    )
  end
  
  def test_type_2_scd
    do_type_2_run(1)
    lines = lines_for('scd_test_type_2.txt')
    
    # TODO: This is a test bug - if the tests don't run at the correct
    # time, this timestamp may not match the timestamp used during the
    # creation of the SCD row
    timestamp = Time.now
    assert_equal(
      "1,Bob,Smith,200 South Drive,Boston,MA,32123,#{timestamp.to_s(:db)},9999-12-31 00:00:00\n", 
      lines.first, "assertion failed in run 1"
    )
    
    do_type_2_run(2)
    lines = lines_for('scd_test_type_2.txt')
    
    assert_equal(
      "1,Bob,Smith,200 South Drive,Boston,MA,32123,#{timestamp.to_s(:db)},#{timestamp.to_s(:db)}\n", 
      lines[0], "assertion failed in run 2"
    )
    assert_equal(
      "2,Bob,Smith,1010 SW 23rd St,Los Angeles,CA,90392,#{timestamp.to_s(:db)},9999-12-31 00:00:00\n", 
      lines[1]
    )
    
    assert_equal 2, count_bobs
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
end