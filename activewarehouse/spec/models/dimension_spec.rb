require File.dirname(__FILE__) + '/../spec_helper'


describe ActiveWarehouse::Report::Dimension, ".new with type column" do
  before(:each) do
		@report = stub_report
		@filters = {:year => ["2006","2007"]}
		@report.should_receive(:column_filters).and_return(@filters)
  end

	it "should match the report's column dimension name" do
	  @dimension = ActiveWarehouse::Report::Dimension.new(:column,@report)
	  @dimension.name.should == "event_date_dimension"
	end

	
	it "should match the report's column dimension class" do
    @dimension = ActiveWarehouse::Report::Dimension.new(:column,@report)
	  @dimension.dimension_class.should == EventDateDimension
	end
	
	it "should match the report's column hierarchy" do
    @dimension = ActiveWarehouse::Report::Dimension.new(:column,@report)
	  @dimension.hierarchy_name.should == :year_hierarchy
	end
	
	it "should match the report's column_constraints" 
	
	it "should match the report's column_filters" do
    @dimension = ActiveWarehouse::Report::Dimension.new(:column,@report)
	  @dimension.filters.should == @filters
	end
	
	it "should match the report's column_stage" do
	  @dimension = ActiveWarehouse::Report::Dimension.new(:column,@report)
		@dimension.stage.should == 1
	end
	
	it "should override the default report's column_stage" do
	  @dimension = ActiveWarehouse::Report::Dimension.new(:column,@report,{:stage => "3"})
		@dimension.stage.should == 3
	end
	
	it "should determine the column hierarchy length" do
	  @dimension = ActiveWarehouse::Report::Dimension.new(:column,@report)
		@dimension.hierarchy_length.should == 3
	end
	
	
	it "should determine the column hierarchy level" do
	  @dimension = ActiveWarehouse::Report::Dimension.new(:column,@report)
		@dimension.hierarchy_level.should == :month 
	end
end


describe ActiveWarehouse::Report::Dimension, ".query_filters" do
  before(:each) do
		@report = stub_report
	  @params = {:ancestors => {"year" => "2006", "month" => "Jan"}, :stage => 2}
		@dimension = ActiveWarehouse::Report::Dimension.column(@report,@params)		
  end

	it "should return a hash of dimension columns included in the params" do
		@dimension.query_filters.should have(2).items
	end
	
	it "should contain the dimension_name.year param" do
	  @dimension.query_filters["event_date_dimension.year"].should == "2006"
	end

end

describe ActiveWarehouse::Report::Dimension, ".values" do
	before(:each) do
		@report = stub_report
		@all_values = ["Jan","Feb","Mar","Apr"]
	end
	
  it "should return a list of values from the dimension's current level"  do
		@dimension = ActiveWarehouse::Report::Dimension.column(@report)	
		@dimension.should_receive(:available_values).any_number_of_times.and_return(@all_values)
		@dimension.should have(4).values
		@dimension.values.should include("Jan")
 	end

  it "should filter the list of values for any filters set" do
		filters = {:month => ["Jan", "Feb"]}
		@report.should_receive(:column_filters).and_return(filters)
		@dimension = ActiveWarehouse::Report::Dimension.column(@report)	
		@dimension.should_receive(:available_values).any_number_of_times.and_return(@all_values)
		@dimension.should have(2).values
		@dimension.values.should include("Jan")	
		@dimension.values.should_not include("Mar")	
  	
  end
end

describe ActiveWarehouse::Report::Dimension, ".ancestors" do
	
	before(:each) do
		@report = stub_report
		@report.stub!(:column_stage).and_return(nil)
	end
		
  it "should return an array of string values for the current level's parents" do
		params = {:ancestors => {"year" => "2006", "month" => "Jan", "day" => "uh-oh"}, :stage => 2}
    @dimension = ActiveWarehouse::Report::Dimension.column(@report, params)	
		@dimension.should have(2).ancestors
		@dimension.ancestors.should include("Jan")
		@dimension.ancestors.should_not include("uh-oh")
  end
end

describe ActiveWarehouse::Report::Dimension, ".has_children?" do
	
	before(:each) do
		@report = stub_report
		@report.stub!(:column_stage).and_return(0)
		@report.stub!(:row_stage).and_return(0)		
	end
		
	it "should return true when there are hierarchy levels and no stage set" do
		params = {}	
    @dimension = ActiveWarehouse::Report::Dimension.row(@report, params)		
		@dimension.should have_children
  end	
		
  it "should return true when there are hierarchy levels beneath the current stage" do
		params = {:ancestors => {"year" => "2006"}, :stage => 1}	
    @dimension = ActiveWarehouse::Report::Dimension.column(@report, params)		
		@dimension.should have_children
  end
		
  it "should return false when there are no hierarchy levels beneath the current stage" do
		params = {:ancestors => {"year" => "2006", "month" => "Jan"}, :stage => 2}	
    @dimension = ActiveWarehouse::Report::Dimension.row(@report, params)		
		@dimension.should_not have_children
  end
end



