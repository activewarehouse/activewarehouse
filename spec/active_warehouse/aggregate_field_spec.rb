require 'spec_helper'

describe ActiveWarehouse::AggregateField do
  
  let(:fact_class) { StoreInventorySnapshotFact }
  let(:column_definition) { double("column definition", name: "quantity_sold", type: nil, limit: nil, scale: nil, precision: nil) } # fact_class.columns_hash["quantity_sold"]
  let(:field) { ActiveWarehouse::AggregateField.new(fact_class, column_definition) }

  describe "#fact_class" do
    it "returns the fact class" do
      expect(field.fact_class).to eq(fact_class)
    end
  end

  describe "#is_semiadditive?" do
    it "returns false" do
      expect(field.is_semiadditive?).to be false
    end

    context "when it is semi-additive" do
      let(:field) { ActiveWarehouse::AggregateField.new(fact_class, column_definition, :sum, :semiadditive => :date) }

      it "returns true" do
        expect(field.is_semiadditive?).to be true
      end
    end
  end

  describe "#semiadditive_over" do
    it "returns nil" do
      expect(field.semiadditive_over).to be_nil
    end

    context "when it is semi-additive" do
      let(:field) { ActiveWarehouse::AggregateField.new(fact_class, column_definition, :sum, :semiadditive => :date) }

      it "returns the semiadditive dimension class" do
        expect(field.semiadditive_over).to eq(DateDimension)
      end
    end
  end

  describe "#strategy_name" do
    it "returns sum" do
      expect(field.strategy_name).to eq(:sum)
    end

    context "when the strategy name is specified" do
      let(:field) { ActiveWarehouse::AggregateField.new(fact_class, column_definition, :count) }

      it "returns the specified strategy name" do
        expect(field.strategy_name).to eq(:count)
      end
    end
  end

  describe "#label" do
    it "returns a generated label" do
      expect(field.label).to eq("store_inventory_snapshot_facts_quantity_sold_sum")
    end

    context "when a label is specified" do
      let(:field) { ActiveWarehouse::AggregateField.new(fact_class, column_definition, :sum, :label => "My Sum") }

      it "returns the specified label" do
        expect(field.label).to eq("My Sum")
      end
    end
  end

  describe "#label_for_table" do
    it "returns a generated label" do
      expect(field.label_for_table).to eq("store_inventory_snapshot_facts_quantity_sold_sum")
    end

    context "when a label is specified" do
       let(:field) { ActiveWarehouse::AggregateField.new(fact_class, column_definition, :sum, :label => "My Sum") }

      it "returns the table name version of the specified label" do
        expect(field.label_for_table).to eq("my_sum")
      end
    end
  end

end
