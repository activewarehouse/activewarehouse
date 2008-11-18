require "#{File.dirname(__FILE__)}/test_helper"

class DateDimension < ActiveWarehouse::Dimension
end

class DimensionTest < Test::Unit::TestCase
  context "a Dimension" do
    should "give a singular table name" do
      assert_equal "date_dimension", DateDimension.table_name
    end
  end
end
