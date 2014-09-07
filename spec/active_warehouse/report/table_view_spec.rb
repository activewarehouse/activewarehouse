require 'spec_helper'

describe ActiveWarehouse::View::TableView do
  
  describe ".new" do

    let(:report) { stub_report }
    let(:params) do
      {
        "c_year" => "2006", "c_month" => "Jan", "crap_param" => "Crap", :cstage => 2,
        "r_year" => "2006", "r_month" => "Jan", "crap_param" => "Crap", :rstage => 2
      }
    end

    let(:table_view) { ActiveWarehouse::View::TableView.new(report, params) }

    it "should set a valid query_result" do
      expect(table_view.query_result).to_not be_nil
    end

    it "should set a valid column dimension" do
      expect(table_view.column_dimension).to_not be_nil
      expect(table_view.column_dimension.stage).to eq(2)
      expect(table_view.column_dimension.hierarchy_length).to eq(3)
    end

    it "should set a valid row dimension" do
      expect(table_view.row_dimension).to_not be_nil
      expect(table_view.row_dimension.stage).to eq(2)
      expect(table_view.row_dimension.hierarchy_length).to eq(3)
    end

    it "should set an array of fact attributes" do
      expect(table_view.fact_attributes.length).to eq(2)
      expect(table_view.fact_attributes[0].label).to eq("Field 1")
    end

    it "should not set any options by default" do
      expect(table_view.with_totals).to eq(false) 
    end

    context "with with_totals set to true" do
      let(:table_view) { ActiveWarehouse::View::TableView.new(report, params, :with_totals => true) }

      it "builds the object" do
        expect(table_view.with_totals).to eq(true)
      end
    end

  end

  describe  ".parse for column" do

    let(:report) { stub_report }
    let(:params) { {"c_year" => "2006", "c_month" => "Jan", "crap_param" => "Crap", :cstage => 2, :rstage => 0} }
    let(:table_view) { ActiveWarehouse::View::TableView.new(report, params) }
    let(:column_params) { table_view.parse(params, :cstage, "c") }

    it "should parse params for the column dimension" do
      expect(column_params.length).to eq(2)
      expect(column_params).to include(:stage)
      expect(column_params).to include(:ancestors)
    end

    it "should determine the stage for the column dimension" do
      expect(column_params[:stage]).to eq(2)
    end

    it "should determine the ancestors from the params" do
      expect(column_params[:ancestors].length).to eq(2)
      expect(column_params[:ancestors]).to have_key("year")
      expect(column_params[:ancestors]["year"]).to eq("2006")
      expect(column_params[:ancestors]).to have_key("month")
      expect(column_params[:ancestors]["month"]).to eq("Jan")
    end

    context "if no cstage is passed to the parameter" do
      let(:params) { {"c_year" => "2006", "c_month" => "Jan", "crap_param" => "Crap", :rstage => 0} }
      it "does not set a stage" do
        expect(column_params).to_not include(:stage)	  
      end
    end

    context "when no ancestor values are found" do
      let(:table_view) { ActiveWarehouse::View::TableView.new(report, {}) }
      let(:column_params) { table_view.parse({},:cstage,"c") }

      it "passes an empty ancestors hash" do
        expect(column_params[:ancestors].length).to eq(0)
      end
    end

  end

  describe ".parse_params for row" do

    let(:report) { stub_report }
    let(:params) {  {"r_year" => "2006", "r_month" => "Jan", "crap_param" => "Crap", :rstage => 2, :cstage => 0} }
    let(:table_view) { ActiveWarehouse::View::TableView.new(report, params) }
    let(:row_params) { table_view.parse(params,:rstage,"r") }

    it "should parse params for the row dimension" do
      expect(row_params.length).to eq(2)
      expect(row_params).to include(:stage)
      expect(row_params).to include(:ancestors)
    end

    it "should determine the stage for the row dimension" do
      expect(row_params[:stage]).to eq(2)
    end

    it "should determine the ancestors from the params" do
      expect(row_params[:ancestors].length).to eq(2)	  
      expect(row_params[:ancestors]).to have_key("year")
      expect(row_params[:ancestors]["year"]).to eq("2006")
      expect(row_params[:ancestors]).to have_key("month")
      expect(row_params[:ancestors]["month"]).to eq("Jan")
    end

    context "with no rstage passed in params" do

      let(:params) {  {"r_year" => "2006", "r_month" => "Jan", "crap_param" => "Crap", :cstage => 0} }

      it "should not set a stage" do
        expect(row_params).to_not include(:stage)	  
      end

    end
  end

  describe ".current_params" do

    let(:report) { stub_report }
    let(:params) { {"r_year" => "2006", "r_month" => "Jan", :rstage => "2",
                    "c_year" => "2007", :cstage => "1"} }
    let(:table_view) { ActiveWarehouse::View::TableView.new(report, params) }

    it "should contain all row ancestors" do
      expect(table_view.current_params).to have_key("r_year")
      expect(table_view.current_params["r_year"]).to eq("2006")
      expect(table_view.current_params).to have_key("r_month")
      expect(table_view.current_params["r_month"]).to eq("Jan")
    end

    it "should contain all column ancestors" do
      expect(table_view.current_params).to have_key("c_year")
      expect(table_view.current_params["c_year"]).to eq("2007")
    end

    it "should contain the cstage" do
      expect(table_view.current_params).to have_key("cstage")
      expect(table_view.current_params["cstage"]).to eq("1")
    end

    it "should contain the rstage" do
      expect(table_view.current_params).to have_key("rstage")
      expect(table_view.current_params["rstage"]).to eq("2")
    end

    it "should contain the report.html_params" do
      allow(report).to receive(:html_params) { {"some_param" => "my_value"} }		
      table_view = ActiveWarehouse::View::TableView.new(report, params)

      expect(table_view.current_params).to have_key("some_param")
      expect(table_view.current_params["some_param"]).to eq("my_value")
    end
  end

  describe ".column_link" do

    let(:report) { stub_report }
    let(:params) { {"r_year" => "2006", "r_month" => "Jan", :rstage => "2",
                    "c_year" => "2007", :cstage => "1"} }
    let(:table_view) { ActiveWarehouse::View::TableView.new(report, params) }
    let(:column_params) { table_view.column_link("Mar") }

    it "should set cstage to 1 level below current setting" do
      expect(column_params).to have_key("cstage")
      expect(column_params["cstage"]).to eq(2)
    end

    it "should add the dimension value to the params" do
      expect(column_params).to have_key("c_month")
      expect(column_params["c_month"]).to eq("Mar")
    end

    it "should merge the current_params" do
      expect(column_params).to have_key("rstage")
      expect(column_params["rstage"]).to eq("2")
      expect(column_params).to have_key("r_year")
      expect(column_params["r_year"]).to eq("2006")
      expect(column_params).to have_key("c_year")
      expect(column_params["c_year"]).to eq("2007")
    end
  end

  describe ".row_link" do

    let(:report) { stub_report }
    let(:params) { {"r_year" => "2006", "r_month" => "Jan", :rstage => "2",
                    "c_year" => "2007", :cstage => "1"} }
    let(:table_view) { ActiveWarehouse::View::TableView.new(report, params) }
    let(:row_params) { table_view.row_link("10") }

    it "should set rstage to 1 level below current setting" do
      expect(row_params).to have_key("rstage")
      expect(row_params["rstage"]).to eq(3)
    end

    it "should add the dimension value to the params" do
      expect(row_params).to have_key("r_day")
      expect(row_params["r_day"]).to eq("10")  
    end

    it "should merge the current_params" do
      expect(row_params).to have_key("cstage")
      expect(row_params["cstage"]).to eq("1")	  
      expect(row_params).to have_key("r_year")
      expect(row_params["r_year"]).to eq("2006")			
      expect(row_params).to have_key("c_year")
      expect(row_params["c_year"]).to eq("2007")	
    end
  end

  describe ".cell_link" do

    let(:report) { stub_report }
    let(:params) { {"r_year" => "2006", "r_month" => "Jan", :rstage => "2",
                    "c_year" => "2007", :cstage => "1"} }
    let(:table_view) { ActiveWarehouse::View::TableView.new(report, params) }
    let(:link_params) { table_view.cell_link("Mar","10") }

    it "should set cstage to 1 level below current setting" do
      expect(link_params).to have_key("cstage")
      expect(link_params["cstage"]).to eq(2)	
    end	

    it "should set rstage to 1 level below current setting" do
      expect(link_params).to have_key("rstage")
      expect(link_params["rstage"]).to eq(3)	
    end

    it "should add the two dimension value to the params" do
      expect(link_params).to have_key("r_day")
      expect(link_params["r_day"]).to eq("10")	  
      expect(link_params).to have_key("c_month")
      expect(link_params["c_month"]).to eq("Mar")		
    end

    it "should merge the current_params" do  
      expect(link_params).to have_key("r_year")
      expect(link_params["r_year"]).to eq("2006")			
      expect(link_params).to have_key("c_year")
      expect(link_params["c_year"]).to eq("2007")	
    end
  end

  describe ".data_columns" do

    let(:report) { stub_report }
    let(:params) { {"r_year" => "2006", "r_month" => "Jan", :rstage => "2",
                    "c_year" => "2007", :cstage => "1"} }
    let(:table_view) { ActiveWarehouse::View::TableView.new(report, params) }
    let(:data_columns) { table_view.data_columns }

    before do
      allow(table_view.column_dimension).to receive(:values) { ["2006","2007"] }
    end

    it "should return an array of DataColumns" do
      expect(data_columns.length).to eq(4)
    end

    it "should return valid DataColumns with fact attributes and dimension values" do
      expect(data_columns[0].label).to eq("Field 1")
      expect(data_columns[0].dimension_value).to eq("2006")
    end
  end

  describe ".data_rows" do

    let(:report) { stub_report }
    let(:params) { {"r_year" => "2006", "r_month" => "Jan", :rstage => "2",
                    "c_year" => "2007", :cstage => "1"} }
    let(:table_view) { ActiveWarehouse::View::TableView.new(report, params) }
    let(:data_rows) { table_view.data_rows }

    before do
      allow(table_view.column_dimension).to receive(:values) { ["2006","2007"] }
      allow(table_view.row_dimension).to receive(:values) { ["2006","2007"] }
    end

    it "should return an array of DataRows" do
      expect(data_rows.length).to eq(2)
    end

    it "should return valid DataRows with cells and dimension values" do
      expect(data_rows.first.cells.length).to eq(4)
      expect(data_rows.first.dimension_value).to eq("2006")
    end
  end

  describe ".data_cell" do
    let(:report) { stub_report }
    let(:params) { {"r_year" => "2006", "r_month" => "Jan", :rstage => "2",
                    "c_year" => "2007", :cstage => "1"} }
    let(:table_view) { ActiveWarehouse::View::TableView.new(report, params) }
    let(:data_column) { table_view.data_columns.first }

    before do
      allow(report).to receive(:format) { { :field1 => Proc.new {|value| sprintf("$%.2f", value)}} }
      allow(table_view.column_dimension).to receive(:values) { ["2006","2007"] }
      allow(ActiveWarehouse::AggregateField).to receive(:===) { true }
      expect(table_view.query_result).to receive(:value).with('row_value', 'column_value', "Field 1") { "1.5" }
    end

    it "should return a non-empty value" do
      expect(table_view.data_cell(data_column.fact_attribute, 'column_value', 'row_value')).to_not be_nil
    end

    it "should format the value" do
      expect(table_view.data_cell(data_column.fact_attribute, 'column_value', 'row_value').value).to eq("$1.50")
    end
  end

  describe ".column_total" do

    let(:report) { stub_report }
    let(:table_view) { ActiveWarehouse::View::TableView.new(report, {}) }
    let(:column1) { double('data_column') }
    let(:column2) { double('data_column2') }
    let(:column3) {  double('data_column3') }
    let(:column4) { double('data_column4') }
    let(:fact_attribute) { double("fact_attribute") }
    let(:text_attribute) { double("text_attribute") }
    let(:cell1) { double('data_cell') }
    let(:cell2) { double('data_cell2') }
    let(:cell3) { double('data_cell3') }
    let(:cell4) { double('data_cell4') }
    let(:row) { double('data_row') }
    let(:field1) { double('field1', :name => :field1) }

    before(:each) do
      allow(report).to receive(:format) { { :field1 => Proc.new {|value| sprintf("$%.2f", value)}} }
      allow(fact_attribute).to receive(:name) { "field0" }
      allow(text_attribute).to receive(:name) { "field3" }
      allow(column1).to receive(:fact_attribute) { fact_attribute }
      allow(column2).to receive(:fact_attribute) { field1 }
      allow(column3).to receive(:fact_attribute) { fact_attribute }
      allow(column4).to receive(:fact_attribute) { text_attribute }
      allow(cell1).to receive(:raw_value) { 4 }
      allow(cell2).to receive(:raw_value) { 1.5 }
      allow(cell3).to receive(:raw_value) { "No Sum" }
      allow(cell4).to receive(:raw_value) { 10.5 }
      allow(row).to receive(:cells) { [cell1, cell2, cell3, cell4] }
      allow(table_view).to receive(:ignore_columns) { [:field3] }
      allow(table_view).to receive(:data_columns) { [column1, column2, column3, column4] }	
      allow(table_view).to receive(:data_rows) { [row, row] }	
    end

    it "should return a grand total for the specified column" do
      expect(table_view.column_total(0)).to eq("8")
      expect(table_view.column_total(1)).to eq("$3.00")
    end

    it "should return an empty string for text fields" do
      expect(table_view.column_total(2)).to eq("")
    end

    it "should return an empty string for columns set to ignore" do
      expect(table_view.column_total(3)).to eq("")
    end
  end

  describe ".row_crumbs" do
    let(:report) { stub_report }
    let(:params) { {"r_year" => "2006", "r_month" => "Jan", :rstage => "2",
                    "c_year" => "2007", :cstage => "1"} }
    let(:table_view) { ActiveWarehouse::View::TableView.new(report, params) }

    it "should return the three crumbs" do
      expect(table_view.row_crumbs.length).to eq(3)
    end

    it "should return crumbs with increasing rstage link params" do
      expect(table_view.row_crumbs[0].link_to_params[:rstage]).to eq('0')
      expect(table_view.row_crumbs[1].link_to_params[:rstage]).to eq('1')
      expect(table_view.row_crumbs[2].link_to_params[:rstage]).to eq('2')
    end

    it "should return crumbs with the expected r_ link params" do
      expect(table_view.row_crumbs[0].link_to_params).to_not include(:r_year)
      expect(table_view.row_crumbs[0].link_to_params).to_not include(:r_month)

      expect(table_view.row_crumbs[1].link_to_params).to include(:r_year)
      expect(table_view.row_crumbs[1].link_to_params).to_not include(:r_month)

      expect(table_view.row_crumbs[2].link_to_params).to include(:r_year)
      expect(table_view.row_crumbs[2].link_to_params).to include(:r_month)
    end

    it "should leave the column link params unmolested" do
      table_view.row_crumbs.each do |crumb|
        expect(crumb.link_to_params).to include(:c_year)
        expect(crumb.link_to_params).to include(:cstage)
      end
    end
  end

  describe ".column_crumbs" do
    let(:report) { stub_report }
    let(:params) { {"r_year" => "2006", "r_month" => "Jan", :rstage => "2", "c_year" => "2007", :cstage => "1"} }
    let(:table_view) { ActiveWarehouse::View::TableView.new(report, params) }

    it "should return two crumbs" do
      expect(table_view.column_crumbs.length).to eq(2)
    end

    it "should return crumbs with increasing cstage link params" do
      expect(table_view.column_crumbs[0].link_to_params[:cstage]).to eq('0')
      expect(table_view.column_crumbs[1].link_to_params[:cstage]).to eq('1')
    end

    it "should return crumbs with the expected c_ link params" do
      expect(table_view.column_crumbs[0].link_to_params).to_not include(:c_year)
      expect(table_view.column_crumbs[1].link_to_params).to include(:c_year)
    end

    it "should leave the row link params unmolested" do
      table_view.column_crumbs.each do |crumb|
        expect(crumb.link_to_params).to include(:r_year)
        expect(crumb.link_to_params).to include(:r_month)
        expect(crumb.link_to_params).to include(:rstage)
      end
    end
  end

  describe ".format_data" do
    let(:report) { stub_report }
    let(:table_view) { ActiveWarehouse::View::TableView.new(report, {}) }

    before do
      allow(report).to receive(:format) { {:field1 => :ignore, :field2 => Proc.new {|f| "$#{f}"}} }
    end 

    it "should accept a block and format the data according to the block's output" do
      expect(table_view.format_data(:field2, 0.01)).to eq("$0.01")
    end

    it "should default to a stringified value of the data" do
      expect(table_view.format_data(:field1, 0.01)).to eq("0.01")
    end

    context "with the :currency format" do
      before do
        allow(report).to receive(:format) { {:field1 => :ignore, :field2 => :currency} }
      end

      it "should return the value using the $0.00 format" do
        expect(table_view.format_data(:field2, 0.01)).to eq("$0.01")
      end
    end
  end

end
