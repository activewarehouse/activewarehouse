require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveWarehouse::Report::DataRow do

  describe ".new" do

    let(:cells) { [] }
    let(:row) { ActiveWarehouse::Report::DataRow.new('my_value', cells) }

    it "should have a row dimension value" do
      expect(row.dimension_value).to eq('my_value')
    end

    it "should start with an empty cell array" do
      expect(row.cells.length).to eq(0)
    end
  end

end
