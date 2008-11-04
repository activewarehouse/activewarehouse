require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveWarehouse::Report::TableReport, ".view" do
	
  before(:each) do
		@report = ActiveWarehouse::Report::TableReport.new(
			:title => "Regional Sales Report",
			:cube_name => :regional_sales_cube, 
			:column_dimension_name => :store, 
			:column_hierarchy => :region,
			:row_dimension_name => :date,
			:row_hierarchy => :cy,
			:fact_attributes => [:cost_dollar_amount, :sales_dollar_amount]
		)
  end	
	
  it "should return a TableView instance" do
    @report.view({}).should be_instance_of(ActiveWarehouse::View::TableView)
  end

	it "should pass through params to the view object" do
	  @report.view(:cstage  => 1).current_params[:cstage].should == 1
	end
	
	it "should accept the with_totals option" do
		@params = {:cstage  => 1}
	  view = @report.view(@params, :with_totals => true)
	
		view.current_params[:cstage].should == 1	  
		view.with_totals?.should be_true
	end
	
	it "should accept a sortable option" do
		@params = {}
	  view = @report.view(@params, :sortable => true)	  
	
		view.sortable?.should be_true
	end
	
	it "should accept a sortable_with_totals convenience option" do
		@params = {}
	  view = @report.view(@params, :sortable_with_totals => true)	  
	
		view.sortable?.should be_true	
		view.with_totals?.should be_true  
	end
end