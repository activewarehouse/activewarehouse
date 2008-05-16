require File.dirname(__FILE__) + '/test_helper'

class Person < ActiveRecord::Base
end
class SourceTest < Test::Unit::TestCase
  def test_file_source
    control = ETL::Control::Control.parse(File.dirname(__FILE__) + 
      '/delimited.ctl')
    configuration = {
      :file => 'data/delimited.txt',
      :parser => :delimited
    }
    definition = [ 
      :first_name,
      :last_name,
      :ssn,
      {
        :name => :age,
        :type => :integer
      },
      :sex
    ]
    
    source = ETL::Control::FileSource.new(control, configuration, definition)
    rows = source.collect { |row| row }
    
    assert_equal 3, rows.length
  end
  
  # Test when the file source is a glob
  def test_file_source_with_glob
    control = ETL::Control::Control.parse(File.dirname(__FILE__) + 
      '/multiple_delimited.ctl')
    configuration = {
      :file => 'data/multiple_delimited_*.txt',
      :parser => :delimited
    }
    definition = [ 
      :first_name,
      :last_name,
      :ssn,
      {
        :name => :age,
        :type => :integer
      }
    ]
    
    source = ETL::Control::FileSource.new(control, configuration, definition)
    rows = source.collect { |row| row }
    
    assert_equal 6, rows.length
  end
  
  def test_file_source_with_absolute_path
    FileUtils.cp(File.dirname(__FILE__) + '/data/delimited.txt', 
      '/tmp/delimited_abs.txt')
    
    control = ETL::Control::Control.parse(File.dirname(__FILE__) + 
      '/delimited_absolute.ctl')
    configuration = {
      :file => '/tmp/delimited_abs.txt',
      :parser => :delimited
    }
    definition = [ 
      :first_name,
      :last_name,
      :ssn,
      {
        :name => :age,
        :type => :integer
      },
      :sex
    ]
    
    source = ETL::Control::FileSource.new(control, configuration, definition)
    rows = source.collect { |row| row }
    
    assert_equal 3, rows.length
  end
  
  # Test support for multiple sources
  def test_multiple_source_delimited
    control = ETL::Control::Control.parse(File.dirname(__FILE__) + 
      '/multiple_source_delimited.ctl')
    rows = control.sources.collect { |source| source.collect { |row| row }}.flatten!
    assert_equal 12, rows.length
  end
  
  # Test database source
  def test_database_source
    Person.delete_all
    assert 0, Person.count
    Person.create(:first_name => 'Bob', :last_name => 'Smith', :ssn => '123456789')
    assert 1, Person.count
    
    control = ETL::Control::Control.parse(File.dirname(__FILE__) + 
      '/delimited.ctl')
    configuration = {
      :database => 'etl_unittest',
      :target => :operational_database,
      :table => 'people',
    }
    definition = [ 
      :first_name,
      :last_name,
      :ssn,
    ]
    source = ETL::Control::DatabaseSource.new(control, configuration, definition)
    assert_match %r{source_data/localhost/etl_unittest/people/\d+.csv}, source.local_file.to_s
    rows = source.collect { |row| row }
    assert 1, rows.length
  end
  
  def test_file_source_with_xml_parser
    control = ETL::Control::Control.parse(File.dirname(__FILE__) + 
      '/xml.ctl')
    rows = control.sources.collect{ |source| source.collect { |row| row }}.flatten!
    assert_equal 2, rows.length
  end
  
  def test_model_source
    control = ETL::Control::Control.parse(File.dirname(__FILE__) + '/model_source.ctl')
    configuration = {
      
    }
    definition = [
      :first_name,
      :last_name,
      :ssn
    ]
  end
end