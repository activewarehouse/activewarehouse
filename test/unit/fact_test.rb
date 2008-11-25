require "#{File.dirname(__FILE__)}/../test_helper"

class FactTest < Test::Unit::TestCase
  context "the Fact class" do
    should "raise an error if dimension_class is called and the specified dimension_name is nil" do
      e = assert_raise(RuntimeError) { ActiveWarehouse::Fact.dimension_class(nil) }
      assert_equal 'Dimension name is nil. This may mean that another class expects your fact to define the specified dimension relationship but the fact class does not.', e.message
    end
  end
  context "a subclass of Fact called OrderFact" do
    should "return its dimensions" do
      assert_equal [:store, :date], OrderFact.dimensions
    end
    should "raise an error if the specified dimension is not defined in the fact" do
      e = assert_raise(RuntimeError) { OrderFact.dimension_class(:foo) }
      assert_equal "Dimension 'foo' is not defined in OrderFact", e.message
    end
  end
end