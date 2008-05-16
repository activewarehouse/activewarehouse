require File.dirname(__FILE__) + '/test_helper'

class Person < ActiveRecord::Base
end

# Test pre- and post-processors
class ProcessorTest < Test::Unit::TestCase
  # Test bulk import functionality
  def test_bulk_import
    assert_nothing_raised do
      control = ETL::Control::Control.new(File.join(File.dirname(__FILE__), 'delimited.ctl'))
      configuration = {
        :file => 'data/bulk_import.txt',
        :truncate => true,
        :target => :data_warehouse,
        :table => 'people'
      }
      processor = ETL::Processor::BulkImportProcessor.new(control, configuration)
      processor.process
    end
    
    assert_equal 3, Person.count
  end
  def test_truncate
    # TODO: implement test
  end
end