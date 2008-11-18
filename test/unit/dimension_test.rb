require "#{File.dirname(__FILE__)}/../test_helper"

class DimensionTest < Test::Unit::TestCase
  context "the Dimension class" do
    should "convert a symbol to the correct class name" do
      assert_equal 'StoreDimension', ActiveWarehouse::Dimension.class_name(:store)
      assert_equal 'StoreDimension', ActiveWarehouse::Dimension.class_name(:store_dimension)
    end
    should "convert a string to the correct class name" do
      assert_equal 'StoreDimension', ActiveWarehouse::Dimension.class_name('store')
      assert_equal 'StoreDimension', ActiveWarehouse::Dimension.class_name('store_dimension')
    end
    should "convert a symbol to the correct class" do
      assert_equal StoreDimension, ActiveWarehouse::Dimension.class_for_name(:store)
      assert_equal StoreDimension, ActiveWarehouse::Dimension.class_for_name(:store_dimension)
    end
    should "convert a string to the correct class" do
      assert_equal StoreDimension, ActiveWarehouse::Dimension.class_for_name('store')
      assert_equal StoreDimension, ActiveWarehouse::Dimension.class_for_name('store_dimension')
    end
    should "convert a symbol to a dimension subclass" do
      assert_equal StoreDimension, ActiveWarehouse::Dimension.to_dimension(:store)
    end
    should "return the same dimension that is provided when a class is sent to to_dimension" do
      assert_equal StoreDimension, ActiveWarehouse::Dimension.to_dimension(StoreDimension)
    end
  end
  context "a subclass of Dimension called StoreDimension" do
    should "give a singular table name" do
      assert_equal "store_dimension", StoreDimension.table_name
    end
    should "convert a symbol to the correct class name" do
      assert_equal 'StoreDimension', StoreDimension.class_name(:store)
      assert_equal 'StoreDimension', StoreDimension.class_name(:store_dimension)
    end
    should "convert a string to the correct class name" do
      assert_equal 'StoreDimension', StoreDimension.class_name('store')
      assert_equal 'StoreDimension', StoreDimension.class_name('store_dimension')
    end
    should "convert a symbol to the correct class" do
      assert_equal StoreDimension, StoreDimension.class_for_name(:store)
      assert_equal StoreDimension, StoreDimension.class_for_name(:store_dimension)
    end
    should "convert a string to the correct class" do
      assert_equal StoreDimension, StoreDimension.class_for_name('store')
      assert_equal StoreDimension, StoreDimension.class_for_name('store_dimension')
    end
    should "convert a symbol to a dimension class" do
      assert_equal StoreDimension, StoreDimension.to_dimension(:store)
    end
    should "return the same dimension that is provided when a class is sent to to_dimension" do
      assert_equal StoreDimension, StoreDimension.to_dimension(StoreDimension)
    end
    should "provide an interface to define hierarchies" do
      location_hierarchy = StoreDimension.hierarchy(:location)
      assert_not_nil location_hierarchy
      assert_equal 3, location_hierarchy.length
      assert_equal [:store_region, :store_state, :store_county], location_hierarchy
    end
    should "provide a hierarchies collection" do
      assert_equal 1, StoreDimension.hierarchies.length
    end
    should "provide a method for determining the last_modified time" do
      assert_not_nil StoreDimension.last_modified
    end
    should "provide the correct foreign key" do
      assert_equal 'store_id', StoreDimension.foreign_key
    end
  end
end
