require File.dirname(__FILE__) + '/test_helper'

class ScdTest < Test::Unit::TestCase
  def setup
    ETL::Engine.connection(:data_warehouse).delete("DELETE FROM person_dimension")
  end
  def test_type_1_scd
    assert_nothing_raised do
      ETL::Engine.process(File.dirname(__FILE__) + '/scd_test_type_1_run_1.ctl')
    end
    lines = File.readlines(File.dirname(__FILE__) + '/output/scd_test_type_1_1.txt')
    assert_equal "Bob,Smith,200 South Drive,Boston,MA,32123\n", lines.first
    
    assert_nothing_raised do
      ETL::Engine.process(File.dirname(__FILE__) + '/scd_test_type_1_run_2.ctl')
    end
    lines = File.readlines(File.dirname(__FILE__) + '/output/scd_test_type_1_2.txt')
    assert_equal "Bob,Smith,1010 SW 23rd St,Los Angeles,CA,90392\n", lines.first
  end
  
  def test_type_2_scd
    ENV['run_number'] = '1'
    assert_nothing_raised do
      ETL::Engine.process(File.dirname(__FILE__) + '/scd_test_type_2.ctl')
    end
    lines = File.readlines(File.dirname(__FILE__) + '/output/scd_test_type_2.txt')
    timestamp = Time.now
    assert_equal(
      "1,Bob,Smith,200 South Drive,Boston,MA,32123,#{timestamp.to_s(:db)},9999-12-31 00:00:00\n", 
      lines.first, "assertion failed in run 1"
    )
    
    ENV['run_number'] = '2'
    assert_nothing_raised do
      ETL::Engine.process(File.dirname(__FILE__) + '/scd_test_type_2.ctl')
    end
    lines = File.readlines(File.dirname(__FILE__) + '/output/scd_test_type_2.txt')
    
    assert_equal(
      "1,Bob,Smith,200 South Drive,Boston,MA,32123,#{timestamp.to_s(:db)},#{timestamp.to_s(:db)}\n", 
      lines[0], "assertion failed in run 2"
    )
    assert_equal(
      "2,Bob,Smith,1010 SW 23rd St,Los Angeles,CA,90392,#{timestamp.to_s(:db)},9999-12-31 00:00:00\n", 
      lines[1]
    )
    
    assert_equal 2.to_s, ETL::Engine.connection(:data_warehouse).select_value(
        "SELECT count(*) FROM person_dimension WHERE first_name = 'Bob' and last_name = 'Smith'")
  end
end