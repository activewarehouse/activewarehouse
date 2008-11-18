require "#{File.dirname(__FILE__)}/../test_helper"

class DimensionTest < Test::Unit::TestCase
  context "the Store dimension" do
    setup do
      StoreDimension.create!(:store_state => 'Florida')
      StoreDimension.create!(:store_state => 'Florida')
      StoreDimension.create!(:store_state => 'Florida')
      StoreDimension.create!(:store_state => 'Georgia')
      StoreDimension.create!(:store_state => 'Alabama')
      StoreDimension.create!(:store_state => 'Alabama')
    end
    context "for the available values" do
      should "return an array of unique available values" do
        assert_equal ['Alabama','Florida','Georgia'], StoreDimension.available_values(:store_state)
      end
    end
  end
end