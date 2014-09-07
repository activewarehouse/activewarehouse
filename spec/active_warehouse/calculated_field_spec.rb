require 'spec_helper'

describe ActiveWarehouse::CalculatedField do

  let(:class_name) { StoreInventorySnapshotFact }
  let(:field_name) { :average_quantity_sold }
  let(:field_type) { :float }
  let(:field) { described_class.new(class_name, field_name) { |r| r[:x] * 10 } }

  describe "#new" do
    context "with an argument error" do
      it "raises an argument error" do
        expect { described_class.new(class_name, :foo) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#owning_class" do
    it "returns the owning class" do
      expect(field.owning_class).to eq(class_name)
    end
  end

  describe "#label" do
    it "returns the generated label" do
      expect(field.label).to eq("store_inventory_snapshot_facts_average_quantity_sold")
    end

    context "with a specified label" do
      let(:field) { described_class.new(class_name, field_name, field_type, :label => "My Sum") { |r| r[:x] } }
      
      it "returns the specified label" do
        expect(field.label).to eq("My Sum")
      end
    end
  end

  describe "#label_for_table" do
    it "returns the generated label" do
      expect(field.label).to eq("store_inventory_snapshot_facts_average_quantity_sold")
    end

    context "with a specified label" do
      let(:field) { described_class.new(class_name, field_name, field_type, :label => "My Sum") { |r| r[:x] } }
      
      it "returns the specified label as a table name" do
        expect(field.label_for_table).to eq("my_sum")
      end
    end
  end

  describe "#calculate" do
    it "returns the calculated value" do
      expect(field.calculate(:x => 2)).to eq(20)
    end
  end
end
