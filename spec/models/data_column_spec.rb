require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveWarehouse::Report::DataColumn do
  
  describe ".new" do

    let(:fact_attribute) { double('fact attribute') }
    let(:column) { described_class.new('MyLabel','my_value', fact_attribute) }

    it "should have a column dimension value" do
      expect(column.dimension_value).to eq('my_value')
    end

    it "should have a fact attribute" do
      expect(column.fact_attribute).to eq(fact_attribute)
    end

    it "should have a label" do
      expect(column.label).to eq("MyLabel")
    end

  end

end
