require 'spec_helper'

describe ActiveWarehouse::CubeQueryResult do
  
  let(:fact_class) { StoreInventorySnapshotFact }
  let(:quantity_sold_column_definition) { double("column definition", name: "quantity_sold", type: nil, limit: nil, scale: nil, precision: nil) }
  let(:dollar_value_at_cost_column_definition) { double("column definition", name: "dollar_value_at_cost", type: nil, limit: nil, scale: nil, precision: nil) }
  let(:strategy_name) { nil }
  let(:aggregate_fields) do
    [
      ActiveWarehouse::AggregateField.new(fact_class, quantity_sold_column_definition, :sum, :label => 'Sum Quantity Sold'),
      ActiveWarehouse::AggregateField.new(fact_class, dollar_value_at_cost_column_definition, :sum, :label => 'Sum Dollar Value At Cost')
    ]
  end
  let(:cqr) { described_class.new(aggregate_fields) }

  describe ".new" do
    context "when the aggregate fields is nil" do
      it "raises an argument error" do
        expect { described_class.new(nil) }.to raise_error(ArgumentError)
      end
    end

    context "when the aggregate fields is an empty array" do
      it "raises an argument error" do
        expect { described_class.new([]) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#add_data" do
    it "adds data to the cube" do
      cqr.add_data('a', 'b', {"Sum Quantity Sold" => 1, "Sum Dollar Value At Cost" => 2})
      expect(cqr.values('a', 'b')).to eq( {"Sum Quantity Sold" => 1, "Sum Dollar Value At Cost" => 2}  )

      cqr.add_data(2003, 'c', {"Sum Quantity Sold" => 1, "Sum Dollar Value At Cost" => 2})
      expect(cqr.values('2003', 'c')).to eq( {"Sum Quantity Sold" => 1, "Sum Dollar Value At Cost" => 2} )
    
      expect(cqr.value('a', 'b', "Sum Quantity Sold")).to eq(1)
      expect(cqr.value('a', 'b', "Sum Dollar Value At Cost")).to eq(2)
      expect(cqr.value('b', 'b', "Sum Dollar Value At Cost")).to eq(0)
    end

    context "when the aggregate field name is incorrect" do
      it "raises an argument error" do
        expect { cqr.add_data('a', 'b', {"doesn't exist" => 1, "Sum Dollar Value At Cost" => 2}) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#has_row_values?" do
    before do
      cqr.add_data('a', 'b', {"Sum Quantity Sold" => 1, "Sum Dollar Value At Cost" => 2})
    end

    context "when values for a row are present" do
      it "returns true" do
        expect(cqr.has_row_values?('a')).to be true
      end
    end

    context "when values for a row are not present" do
      it "returns false" do
        expect(cqr.has_row_values?('b')).to be false
      end
    end
  end

end

def aggregate(name, options)
  ActiveWarehouse::AggregateField.new(fact_class, column_definition, strategy_name)
end
