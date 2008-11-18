require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveWarehouse::View::TableView, ".new" do
	
  before(:each) do
		@report = stub_report
		@params = {"c_year" => "2006", "c_month" => "Jan", "crap_param" => "Crap", :cstage => 2,
			"r_year" => "2006", "r_month" => "Jan", "crap_param" => "Crap", :rstage => 2}
		@table_view = ActiveWarehouse::View::TableView.new(@report, @params)
  end	
	
  it "should set a valid query_result" do
   	@table_view.query_result.should_not be_nil
  end

	it "should set a valid column dimension" do
		@table_view.column_dimension.should_not be_nil
		@table_view.column_dimension.stage.should == 2
		@table_view.column_dimension.hierarchy_length.should == 3
	end

	it "should set a valid row dimension" do
		@table_view.row_dimension.should_not be_nil
		@table_view.row_dimension.stage.should == 2
		@table_view.row_dimension.hierarchy_length.should == 3
	end
	
	it "should set an array of fact attributes" do
   	@table_view.fact_attributes.should have(2).items
		@table_view.fact_attributes[0].label.should == "Field 1"
	end
	
	it "should not set any options by default" do
	  @table_view.with_totals.should be_false
	end
	
	it "should accept an option of with_totals" do
	  @view = ActiveWarehouse::View::TableView.new(@report, @params, :with_totals => true)
		@view.with_totals.should be_true
	end	
end

describe ActiveWarehouse::View::TableView, ".parse for column" do

  before(:each) do
		@report = stub_report
		@params = {"c_year" => "2006", "c_month" => "Jan", "crap_param" => "Crap", :cstage => 2, :rstage => 0}
	  @table_view = ActiveWarehouse::View::TableView.new(@report, @params)
		@column_params = @table_view.parse(@params,:cstage,"c")
  end

	it "should parse params for the column dimension" do
		@column_params.should have(2).items
		@column_params.should include(:stage)
		@column_params.should include(:ancestors)
	end
	
	it "should determine the stage for the column dimension" do
		@column_params[:stage].should == 2
	end
		
	it "should determine the ancestors from the params" do
		@column_params[:ancestors].should have(2).items	  
		@column_params[:ancestors].should have_key("year")
		@column_params[:ancestors]["year"].should == "2006"
		@column_params[:ancestors].should have_key("month")
		@column_params[:ancestors]["month"].should == "Jan"
	end
	
	it "should not set a stage if no cstage is passed in the params" do
		@params.delete(:cstage)
	  @table_view = ActiveWarehouse::View::TableView.new(@report, @params)
		@column_params = @table_view.parse(@params,:cstage,"c")
		@column_params.should_not include(:stage)	  
	end
	
	it "should pass an empty ancestors hash when no ancestor values are found" do
	  @table_view = ActiveWarehouse::View::TableView.new(@report, {})
		@column_params = @table_view.parse({},:cstage,"c")
		@column_params[:ancestors].should have(0).items	  
	end
end

describe ActiveWarehouse::View::TableView, ".parse_params for row" do

  before(:each) do
		@report = stub_report
		@params = {"r_year" => "2006", "r_month" => "Jan", "crap_param" => "Crap", :rstage => 2, :cstage => 0}
	  @table_view = ActiveWarehouse::View::TableView.new(@report, @params)
		@row_params = @table_view.parse(@params,:rstage,"r")
  end

	it "should parse params for the row dimension" do
		@row_params.should have(2).items
		@row_params.should include(:stage)
		@row_params.should include(:ancestors)
	end
	
	it "should determine the stage for the row dimension" do
		@row_params[:stage].should == 2
	end
		
	it "should determine the ancestors from the params" do
		@row_params[:ancestors].should have(2).items	  
		@row_params[:ancestors].should have_key("year")
		@row_params[:ancestors]["year"].should == "2006"
		@row_params[:ancestors].should have_key("month")
		@row_params[:ancestors]["month"].should == "Jan"
	end
	
	it "should not set a stage if no rstage is passed in the params" do
		@params.delete(:rstage)
	  @table_view = ActiveWarehouse::View::TableView.new(@report, @params)
		@row_params = @table_view.parse(@params,:rstage,"r")
		@row_params.should_not include(:stage)	  
	end
end

describe ActiveWarehouse::View::TableView, ".current_params" do
	
  before(:each) do
		@report = stub_report

		@params = {"r_year" => "2006", "r_month" => "Jan", :rstage => "2",
			"c_year" => "2007", :cstage => "1"}
	  @table_view = ActiveWarehouse::View::TableView.new(@report, @params)
  end
	
  it "should contain all row ancestors" do
    @table_view.current_params.should have_key("r_year")
    @table_view.current_params["r_year"].should == "2006"
    @table_view.current_params.should have_key("r_month")
    @table_view.current_params["r_month"].should == "Jan"
  end

	it "should contain all column ancestors" do
    @table_view.current_params.should have_key("c_year")
    @table_view.current_params["c_year"].should == "2007" 
	end
	
	it "should contain the cstage" do
    @table_view.current_params.should have_key("cstage")
    @table_view.current_params["cstage"].should == "1"	  
	end
	
	it "should contain the rstage" do
    @table_view.current_params.should have_key("rstage")
    @table_view.current_params["rstage"].should == "2"	  
	end
	
	it "should contain the report.html_params" do
		@report.stub!(:html_params).and_return({"some_param" => "my_value"})		
	  @table_view = ActiveWarehouse::View::TableView.new(@report, @params)		
	
    @table_view.current_params.should have_key("some_param")
    @table_view.current_params["some_param"].should == "my_value"		
	end
end

describe ActiveWarehouse::View::TableView, ".column_link" do
	
  before(:each) do
		@report = stub_report

		@params = {"r_year" => "2006", "r_month" => "Jan", :rstage => "2",
			"c_year" => "2007", :cstage => "1"}
	  @table_view = ActiveWarehouse::View::TableView.new(@report, @params)
		@column_params = @table_view.column_link("Mar")
  end
	
  it "should set cstage to 1 level below current setting" do
		@column_params.should have_key("cstage")
		@column_params["cstage"].should == 2	
  end

	it "should add the dimension value to the params" do
		@column_params.should have_key("c_month")
		@column_params["c_month"].should == "Mar"	  
	end
	
	it "should merge the current_params" do
		@column_params.should have_key("rstage")
		@column_params["rstage"].should == "2"	  
		@column_params.should have_key("r_year")
		@column_params["r_year"].should == "2006"			
		@column_params.should have_key("c_year")
		@column_params["c_year"].should == "2007"	
	end
end

describe ActiveWarehouse::View::TableView, ".row_link" do
	
  before(:each) do
		@report = stub_report

		@params = {"r_year" => "2006", "r_month" => "Jan", :rstage => "2",
			"c_year" => "2007", :cstage => "1"}
	  @table_view = ActiveWarehouse::View::TableView.new(@report, @params)
		@row_params = @table_view.row_link("10")
  end
	
  it "should set rstage to 1 level below current setting" do
		@row_params.should have_key("rstage")
		@row_params["rstage"].should == 3	
  end

	it "should add the dimension value to the params" do
		@row_params.should have_key("r_day")
		@row_params["r_day"].should == "10"	  
	end
	
	it "should merge the current_params" do
		@row_params.should have_key("cstage")
		@row_params["cstage"].should == "1"	  
		@row_params.should have_key("r_year")
		@row_params["r_year"].should == "2006"			
		@row_params.should have_key("c_year")
		@row_params["c_year"].should == "2007"	
	end
end


describe ActiveWarehouse::View::TableView, ".cell_link" do
	
  before(:each) do
		@report = stub_report

		@params = {"r_year" => "2006", "r_month" => "Jan", :rstage => "2",
			"c_year" => "2007", :cstage => "1"}
	  @table_view = ActiveWarehouse::View::TableView.new(@report, @params)
		@link_params = @table_view.cell_link("Mar","10")
  end
	
  it "should set cstage to 1 level below current setting" do
		@link_params.should have_key("cstage")
		@link_params["cstage"].should == 2	
  end	

  it "should set rstage to 1 level below current setting" do
		@link_params.should have_key("rstage")
		@link_params["rstage"].should == 3	
  end

	it "should add the two dimension value to the params" do
		@link_params.should have_key("r_day")
		@link_params["r_day"].should == "10"	  
		@link_params.should have_key("c_month")
		@link_params["c_month"].should == "Mar"		
	end
	
	it "should merge the current_params" do  
		@link_params.should have_key("r_year")
		@link_params["r_year"].should == "2006"			
		@link_params.should have_key("c_year")
		@link_params["c_year"].should == "2007"	
	end
end


describe ActiveWarehouse::View::TableView, ".data_columns" do
	
  before(:each) do
		@report = stub_report
		@params = {"r_year" => "2006", "r_month" => "Jan", :rstage => "2",
			"c_year" => "2007", :cstage => "1"}
	  @table_view = ActiveWarehouse::View::TableView.new(@report, @params)
		@table_view.column_dimension.stub!(:values).and_return(["2006","2007"])	
		@data_columns = @table_view.data_columns
  end
	
  it "should return an array of DataColumns" do
    @data_columns.should have(4).items
  end

	it "should return valid DataColumns with fact attributes and dimension values" do
	  @data_columns[0].label.should == "Field 1"
	  @data_columns[0].dimension_value.should == "2006"
	end
end

describe ActiveWarehouse::View::TableView, ".data_rows" do
	
  before(:each) do
		@report = stub_report
		@params = {"r_year" => "2006", "r_month" => "Jan", :rstage => "2",
			"c_year" => "2007", :cstage => "1"}
	  @table_view = ActiveWarehouse::View::TableView.new(@report, @params)
		@table_view.column_dimension.stub!(:values).and_return(["2006","2007"])	
		@table_view.row_dimension.stub!(:values).and_return(["2006","2007"])	
		@data_rows = @table_view.data_rows
  end
	
  it "should return an array of DataRows" do
    @data_rows.should have(2).items
  end
	
	it "should return valid DataRows with cells and dimension values" do
	  @data_rows.first.cells.should have(4).items
	  @data_rows.first.dimension_value.should == "2006"
	end
end

describe ActiveWarehouse::View::TableView, ".data_cell" do
  before(:each) do
		@report = stub_report
		@report.stub!(:format).and_return({ :field1 => Proc.new {|value| sprintf("$%.2f", value)}})
		@params = {"r_year" => "2006", "r_month" => "Jan", :rstage => "2",
			"c_year" => "2007", :cstage => "1"}
	  @table_view = ActiveWarehouse::View::TableView.new(@report, @params)
		@table_view.column_dimension.stub!(:values).and_return(["2006","2007"])	
		@data_column = @table_view.data_columns.first
		ActiveWarehouse::AggregateField.stub!(:===).and_return(true)
		@table_view.query_result.should_receive(:value).with('row_value', 'column_value', "Field 1").and_return("1.5")		
	end

  it "should return a non-empty value" do
    @table_view.data_cell(@data_column.fact_attribute, 'column_value', 'row_value').should_not be_nil
  end

  it "should format the value" do
    @table_view.data_cell(@data_column.fact_attribute, 'column_value', 'row_value').value.should == "$1.50"
  end
end

describe ActiveWarehouse::View::TableView, ".column_total" do
	
  before(:each) do
		@report = stub_report
		@report.stub!(:format).and_return({ :field1 => Proc.new {|value| sprintf("$%.2f", value)}})
	  @table_view = ActiveWarehouse::View::TableView.new(@report, {})
		@column1 = mock('data_column')
		@column2 = mock('data_column2')
		@column3 = mock('data_column3')
		@column4 = mock('data_column4')
		@fact_attribute= mock("fact_attribute")
		@fact_attribute.stub!(:name).and_return("field0")			
		@text_attribute= mock("text_attribute")
		@text_attribute.stub!(:name).and_return("field3")		
		@column1.stub!(:fact_attribute).and_return(@fact_attribute)
		@column2.stub!(:fact_attribute).and_return(@field1)		
		@column3.stub!(:fact_attribute).and_return(@fact_attribute)
		@column4.stub!(:fact_attribute).and_return(@text_attribute)
		@cell1 = mock('data_cell')
		@cell1.stub!(:raw_value).and_return(4)
		@cell2 = mock('data_cell2')
		@cell2.stub!(:raw_value).and_return(1.5)
		@cell3 = mock('data_cell3')
		@cell3.stub!(:raw_value).and_return("No Sum")
		@cell4 = mock('data_cell4')
		@cell4.stub!(:raw_value).and_return(10.5)	
		@row = mock('data_row')
		@row.stub!(:cells).and_return([@cell1,@cell2,@cell3,@cell4])
		
		@table_view.stub!(:ignore_columns).and_return([:field3])
		
		@table_view.stub!(:data_columns).and_return([@column1, @column2, @column3, @column4])	
		@table_view.stub!(:data_rows).and_return([@row,@row])	
	end

  it "should return a grand total for the specified column" do
    @table_view.column_total(0).should == "8"
    @table_view.column_total(1).should == "$3.00"
  end

	it "should return an empty string for text fields" do
	  @table_view.column_total(2).should == ""
	end
	
	it "should return an empty string for columns set to ignore" do
	  @table_view.column_total(3).should == ""
	end
end


describe ActiveWarehouse::View::TableView, ".row_crumbs" do
  before(:each) do
		@report = stub_report
		@params = {"r_year" => "2006", "r_month" => "Jan", :rstage => "2",
			"c_year" => "2007", :cstage => "1"}
	  @table_view = ActiveWarehouse::View::TableView.new(@report, @params)
	end
	
  it "should return the three crumbs" do
    @table_view.row_crumbs.should have(3).items
  end
	
  it "should return crumbs with increasing rstage link params" do
    @table_view.row_crumbs[0].link_to_params[:rstage].should == '0'
    @table_view.row_crumbs[1].link_to_params[:rstage].should == '1'
    @table_view.row_crumbs[2].link_to_params[:rstage].should == '2'
  end
  
  it "should return crumbs with the expected r_ link params" do
    @table_view.row_crumbs[0].link_to_params.should_not include(:r_year)
    @table_view.row_crumbs[0].link_to_params.should_not include(:r_month)

    @table_view.row_crumbs[1].link_to_params.should include(:r_year)
    @table_view.row_crumbs[1].link_to_params.should_not include(:r_month)

    @table_view.row_crumbs[2].link_to_params.should include(:r_year)
    @table_view.row_crumbs[2].link_to_params.should include(:r_month)
  end
  
  it "should leave the column link params unmolested" do
    @table_view.row_crumbs.each do |crumb|
      crumb.link_to_params.should include(:c_year)
      crumb.link_to_params.should include(:cstage)
    end
  end
end

describe ActiveWarehouse::View::TableView, ".column_crumbs" do
  before(:each) do
		@report = stub_report
		@params = {"r_year" => "2006", "r_month" => "Jan", :rstage => "2",
			"c_year" => "2007", :cstage => "1"}
	  @table_view = ActiveWarehouse::View::TableView.new(@report, @params)
	end
	
  it "should return two crumbs" do
    @table_view.column_crumbs.should have(2).items
  end
	
  it "should return crumbs with increasing cstage link params" do
    @table_view.column_crumbs[0].link_to_params[:cstage].should == '0'
    @table_view.column_crumbs[1].link_to_params[:cstage].should == '1'
  end
  
  it "should return crumbs with the expected c_ link params" do
    @table_view.column_crumbs[0].link_to_params.should_not include(:c_year)
    @table_view.column_crumbs[1].link_to_params.should include(:c_year)
  end
  
  it "should leave the row link params unmolested" do
    @table_view.column_crumbs.each do |crumb|
      crumb.link_to_params.should include(:r_year)
      crumb.link_to_params.should include(:r_month)
      crumb.link_to_params.should include(:rstage)
    end
  end
end

describe ActiveWarehouse::View::TableView, ".format_data" do
	
  before(:each) do
		@report = stub_report
		@report.stub!(:format).and_return({:field1 => :ignore, :field2 => Proc.new {|f| "$#{f}"}})
	  @table_view = ActiveWarehouse::View::TableView.new(@report, {})
	end
	
  it "should return convert :currency to $0.00 format" do 
		@report.stub!(:format).and_return({:field1 => :ignore, :field2 => :currency})
	  @table_view = ActiveWarehouse::View::TableView.new(@report, {})	
    @table_view.format_data(:field2, 0.01).should eql("$0.01")
  end

	it "should accept a block and format the data according to the block's output" do
	  @table_view.format_data(:field2, 0.01).should eql("$0.01")
	end
	
	it "should default to a stringified value of the data" do
	  @table_view.format_data(:field1, 0.01).should eql("0.01")
	end
end

def stub_report
	@report = mock('report')
	@cube = mock('cube')
	query_result = mock('query_result')
	@cube.stub!(:query).and_return(query_result)
	eval("class CustomerFact < ActiveWarehouse::Fact;  end")
	eval("class EventDateDimension < ActiveWarehouse::Dimension; define_hierarchy :year_hierarchy, [:year, :month, :day]; end")
	
	@field1 = mock('field1')
	@field1.stub!(:label).and_return("Field 1")
	@field1.stub!(:name).and_return("field1")
	CustomerFact.stub!(:field_for_name).and_return(@field1)
	@report.stub!(:fact_class).and_return(CustomerFact)
	@report.stub!(:fact_attributes).and_return([:field1,:field2])
	
	@report.stub!(:cube).and_return(@cube)
	@report.stub!(:conditions).and_return({})
	@report.stub!(:column_dimension_class).and_return(EventDateDimension)
	@report.stub!(:column_dimension_name).and_return("event_date_dimension")
	@report.stub!(:column_hierarchy).and_return(:year_hierarchy)
	@report.stub!(:column_stage).and_return(1)
	@report.stub!(:column_filters).and_return({})
	@report.stub!(:column_param_prefix).and_return('c')
	@report.stub!(:format).and_return({})
	@report.stub!(:html_params).and_return({})			
	@report.stub!(:row_dimension_class).and_return(EventDateDimension)
	@report.stub!(:row_dimension_name).and_return("event_date_dimension")
	@report.stub!(:row_hierarchy).and_return(:year_hierarchy)
	@report.stub!(:row_stage).and_return(1)
	@report.stub!(:row_filters).and_return({})
	@report.stub!(:row_param_prefix).and_return('r')	
	@report
end