require "#{File.dirname(__FILE__)}/test_helper"

class DimensionTest < Test::Unit::TestCase
  context "the Store dimension" do
    setup do
      StoreDimension.create!(:store_state => 'Florida', :store_region => 'South')
      StoreDimension.create!(:store_state => 'Florida', :store_region => 'South')
      StoreDimension.create!(:store_state => 'Florida', :store_region => 'South')
      StoreDimension.create!(:store_state => 'Georgia', :store_region => 'South')
      StoreDimension.create!(:store_state => 'Alabama', :store_region => 'South')
      StoreDimension.create!(:store_state => 'Alabama', :store_region => 'South')
    end
    context "for the available values" do
      should "return an array of unique available values" do
        assert_equal ['Alabama','Florida','Georgia'], StoreDimension.available_values(:store_state)
        assert_equal ['South'], StoreDimension.available_values(:store_region)
      end
    end
  end
end