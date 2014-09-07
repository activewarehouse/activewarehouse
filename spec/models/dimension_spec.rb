require File.dirname(__FILE__) + '/../spec_helper'


describe ActiveWarehouse::Report::Dimension do
  describe ".new with type column" do
    let(:report) { stub_report }
    let(:filters) { {:year => ["2006","2007"]} }
    let(:dimension) { ActiveWarehouse::Report::Dimension.new(:column, report) }

    before do
      expect(report).to receive(:column_filters) { filters }
    end

    it "should match the report's column dimension name" do
      expect(dimension.name).to eq("event_date_dimension")
    end

    it "should match the report's column dimension class" do
      expect(dimension.dimension_class).to eq(EventDateDimension)
    end

    it "should match the report's column hierarchy" do
      expect(dimension.hierarchy_name).to eq(:year_hierarchy)
    end

    it "should match the report's column_constraints"

    it "should match the report's column_filters" do
      expect(dimension.filters).to eq(filters)
    end

    it "should match the report's column_stage" do
      expect(dimension.stage).to eq(1)
    end

    context "with an overridden column stage" do
      let(:dimension) { ActiveWarehouse::Report::Dimension.new(:column, report, {:stage => "3"}) }

      it "returns the overridden the default report's column_stage" do
        expect(dimension.stage).to eq(3)
      end
    end

    it "should determine the column hierarchy length" do
      expect(dimension.hierarchy_length).to eq(3)
    end


    it "should determine the column hierarchy level" do
      expect(dimension.hierarchy_level).to eq(:month)
    end
  end

  describe ".query_filters" do
    let(:report) { stub_report }
    let(:params) { {:ancestors => {"year" => "2006", "month" => "Jan"}, :stage => 2} }
    let(:dimension) { ActiveWarehouse::Report::Dimension.column(report, params) }

    it "should return a hash of dimension columns included in the params" do
      expect(dimension.query_filters.length).to eq(2)
    end

    it "should contain the dimension_name.year param" do
      expect(dimension.query_filters["event_date_dimension.year"]).to eq("2006")
    end

  end

  describe ".values" do
    let(:report) { stub_report }
    let(:all_values) { ["Jan","Feb","Mar","Apr"] }
    let(:dimension) { ActiveWarehouse::Report::Dimension.column(report) }

    context "with no filters" do
      before do
        allow(dimension).to receive(:available_values) { all_values }
      end

      it "should return a list of values from the dimension's current level"  do
        expect(dimension.values.length).to eq(4)
        expect(dimension.values).to include("Jan")
      end
    end

    context "when filtered" do
      let(:filters) { {:month => ["Jan", "Feb"]} }

      before do
        expect(report).to receive(:column_filters) { filters }
        allow(dimension).to receive(:available_values) { all_values }
      end

      it "should filter the list of values for any filters set" do 
        expect(dimension.values.length).to eq(2)
        expect(dimension.values).to include("Jan")	
        expect(dimension.values).to_not include("Mar")	
      end
    end
  end

  describe ".ancestors" do

    let(:report) { stub_report }
    let(:params) { {:ancestors => {"year" => "2006", "month" => "Jan", "day" => "uh-oh"}, :stage => 2} }
    let(:dimension) { ActiveWarehouse::Report::Dimension.column(report, params) }

    before do
      allow(report).to receive(:column_stage) { nil }
    end

    it "should return an array of string values for the current level's parents" do
      expect(dimension.ancestors.length).to eq(2)
      expect(dimension.ancestors).to include("Jan")
      expect(dimension.ancestors).to_not include("uh-oh")
    end
  end

  describe ".has_children?" do

    let(:report) { stub_report }

    before do
      allow(report).to receive(:column_stage) { 0 }
      allow(report).to receive(:row_stage) { 0 }		
    end

    context "when there are hierarchy levels and no stage set" do
      let(:params) { {} }

      it "should return true" do
        dimension = ActiveWarehouse::Report::Dimension.row(report, params)		
        expect(dimension).to have_children
      end
    end

    context "when there are hierarchy levels beneath the current stage" do
      let(:params) { {:ancestors => {"year" => "2006"}, :stage => 1} }
      it "should return true" do
        dimension = ActiveWarehouse::Report::Dimension.column(report, params)		
        expect(dimension).to have_children
      end
    end

    context "when there are no hierarchy levels beneath the current stage" do
      let(:params) { {:ancestors => {"year" => "2006", "month" => "Jan"}, :stage => 2} }
      it "should return false" do
        dimension = ActiveWarehouse::Report::Dimension.row(@report, params)		
        expect(dimension).to_not have_children
      end
    end
  end

end



