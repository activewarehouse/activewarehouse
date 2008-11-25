require "#{File.dirname(__FILE__)}/test_helper"

class DimensionTest < Test::Unit::TestCase
  context "the Store dimension" do
    setup do
      StoreDimension.create!(:store_region => 'South', :store_state => 'Florida', :store_county => 'Brevard')
      StoreDimension.create!(:store_region => 'South', :store_state => 'Florida', :store_county => 'Seminole')
      StoreDimension.create!(:store_region => 'South', :store_state => 'Florida', :store_county => 'Flagler')
      StoreDimension.create!(:store_region => 'South', :store_state => 'Georgia', :store_county => 'Bacon')
      StoreDimension.create!(:store_region => 'South', :store_state => 'Alabama', :store_county => 'Jefferson')
      StoreDimension.create!(:store_region => 'South', :store_state => 'Alabama', :store_county => 'Montgomery')
      StoreDimension.create!(:store_region => 'North', :store_state => 'New York', :store_county => 'Albany')
      StoreDimension.create!(:store_region => 'North', :store_state => 'Deleware', :store_county => 'Dover')
    end
    teardown do
      StoreDimension.delete_all
    end
    context "the interface for retrieving available values" do
      should "return an array of unique available values" do
        assert_equal ['North','South'], StoreDimension.available_values(:store_region)
        assert_equal ['Alabama','Deleware','Florida','Georgia','New York'], StoreDimension.available_values(:store_state)
        assert_equal ["Albany","Bacon","Brevard"], StoreDimension.available_values(:store_county)[0, 3]
      end
    end
    context "the interface for retrieving available child values" do
      should "return an array of unique available child values" do
        assert_equal ["Alabama","Florida","Georgia"], StoreDimension.available_child_values(:location, ["South"])
        assert_equal ["Bacon"], StoreDimension.available_child_values(:location, ["South", "Georgia"])
      end
      should "raise an error if the hierarchy depth is exceeded" do
        assert_raise ArgumentError do
          StoreDimension.available_child_values(:location, ["South", "Georgia", "Bacon"])
        end
      end
    end
    context "the interface for retrieving a tree of available values" do
      setup do
        @root = StoreDimension.available_values_tree(:location)
      end
      should "have a root with the value of 'All'" do
        assert_equal 'All', @root.value
      end
      should "have a child" do
        assert @root.has_child?('South'), 'Root node does not have child South'
      end
      should "have children" do
        assert_equal ['North','South'], @root.children.collect { |node| node.value }
      end
    end
    context "the interface for retrieving a denominator count" do
      should "return the correct count when the denominator level is not specified" do
        assert_equal 6, StoreDimension.denominator_count(:location, :store_region)["South"]
        assert_equal 2, StoreDimension.denominator_count(:location, :store_region)["North"]
        assert_equal 3, StoreDimension.denominator_count(:location, :store_state)["Florida"]
      end
      should "return the correct count when the denominator level is specified" do
        assert_equal 3, StoreDimension.denominator_count(:location, :store_region, :store_state)["South"]
        assert_equal 2, StoreDimension.denominator_count(:location, :store_region, :store_state)["North"]
      end
      should "return nil if there is no value for the given hierarchy level" do
        assert_nil StoreDimension.denominator_count(:location, :store_region)["West"]
      end
    end
  end
end