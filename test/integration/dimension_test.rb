require "#{File.dirname(__FILE__)}/test_helper"

class DimensionTest < Test::Unit::TestCase
  context "the Store dimension" do
    setup do
      StoreDimension.create!(:store_state => 'Florida', :store_region => 'South', :store_county => 'Brevard')
      StoreDimension.create!(:store_state => 'Florida', :store_region => 'South', :store_county => 'Seminole')
      StoreDimension.create!(:store_state => 'Florida', :store_region => 'South', :store_county => 'Flagler')
      StoreDimension.create!(:store_state => 'Georgia', :store_region => 'South', :store_county => 'Bacon')
      StoreDimension.create!(:store_state => 'Alabama', :store_region => 'South', :store_county => 'Jefferson')
      StoreDimension.create!(:store_state => 'Alabama', :store_region => 'South', :store_county => 'Montgomery')
      StoreDimension.create!(:store_state => 'New York', :store_region => 'North', :store_county => 'Albany')
      StoreDimension.create!(:store_state => 'Deleware', :store_region => 'North', :store_county => 'Dover')
    end
    context "for the available values" do
      should "return an array of unique available values" do
        assert_equal ['Alabama','Deleware','Florida','Georgia','New York'], StoreDimension.available_values(:store_state)
        assert_equal ['North','South'], StoreDimension.available_values(:store_region)
      end
    end
    context "for the available child values" do
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
  end
end