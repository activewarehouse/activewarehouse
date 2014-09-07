require 'spec_helper'

describe ActiveWarehouse::Report::DataCell do
  
  describe ".new" do

    let(:fact_attribute) { double('fact_attribute') }
    let(:column_dimension_value) { "Something" }
    let(:row_dimension_value) { "2006" }
    let(:value) { "1.1" }
    let(:raw_value) { 1.1 }
    let(:cell) { ActiveWarehouse::Report::DataCell.new(column_dimension_value, row_dimension_value, fact_attribute, raw_value, value) }

    it "should have a row dimension value" do
      expect(cell.row_dimension_value).to eq(row_dimension_value)
    end

    it "should have a column dimension value" do
      expect(cell.column_dimension_value).to eq(column_dimension_value)
    end

    it "should have a fact attribute" do
      expect(cell.fact_attribute).to eq(fact_attribute)
    end

    it "should have a value" do
      expect(cell.value).to eq(value)
    end

    it "should have a raw value" do
      expect(cell.raw_value).to eq(raw_value)
    end
  end
end
