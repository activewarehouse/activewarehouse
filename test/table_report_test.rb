require "#{File.dirname(__FILE__)}/test_helper"

class TableReportTest < Test::Unit::TestCase
  include ActiveWarehouse::Report
  
  def test_true
  end
  
#  def test_new
#    assert_equal 'My Report', report.title
#    assert_equal RegionalSalesCube, report.cube.class
#    assert_equal PosRetailSalesTransactionFact, report.fact_class
#    assert_equal DateDimension, report.column_dimension_class
#    assert_equal StoreDimension, report.row_dimension_class
#    assert_equal :cy, report.column_hierarchy
#    assert_equal ['2004','2005','2006'], report.column_constraints
#    assert_equal :region, report.row_hierarchy
#    assert_equal ['Northeast','Southeast'], report.row_constraints
#    assert_equal [:sales_quantity], report.fact_attributes
#    assert_equal 'col', report.column_param_prefix
#    assert_equal 'row', report.row_param_prefix
#    assert_not_nil report.format
#    assert_not_nil report.format[:gross_margin]
#  end
#  
#  def test_persistent_report
#    assert_nothing_raised do
#      report.save!
#    end
#    assert_not_nil report.id
#    
#    p_report = TableReport.find(report.id)
#    assert_equal 'My Report', p_report.title
#    assert_equal RegionalSalesCube, p_report.cube.class
#    assert_equal PosRetailSalesTransactionFact, p_report.fact_class
#    assert_equal DateDimension, p_report.column_dimension_class
#    assert_equal StoreDimension, p_report.row_dimension_class
#    assert_equal :cy, p_report.column_hierarchy
#    assert_equal ['2004','2005','2006'], p_report.column_constraints
#    assert_equal :region, p_report.row_hierarchy
#    assert_equal ['Northeast','Southeast'], p_report.row_constraints
#    assert_equal [:sales_quantity], p_report.fact_attributes
#    assert_equal 'col', p_report.column_param_prefix
#    assert_equal 'row', p_report.row_param_prefix
#    assert_not_nil p_report.format
#    assert_equal({}, p_report.format)
#  end
#  
#  def test_defaults
#    report = TableReport.new(
#      :title => 'Test Report',
#      :cube_name => :regional_sales, 
#      :column_dimension_name => :date,
#      :row_dimension_name => :store
#    )
#    
#    # test before save
#    assert_defaults(report)
#    
#    assert_nothing_raised do
#      report.save!
#    end
#    # test after save
#    assert_defaults(report)
#    
#    # test after find
#    report = TableReport.find(report.id)
#    assert_defaults(report)
#  end
  
  protected
  def assert_defaults(report)
    assert_equal :cy, report.column_hierarchy
    assert_equal :location, report.row_hierarchy
    assert_equal [:sales_quantity, :sales_dollar_amount, :cost_dollar_amount, :gross_profit_dollar_amount, :gross_margin], report.fact_attributes
    assert_equal 'c', report.column_param_prefix
    assert_equal 'r', report.row_param_prefix
  end
  def report
    unless @report
      @report = TableReport.new(
        :title => 'My Report', 
        :cube_name => :regional_sales, 
        :column_dimension_name => :date,
        :row_dimension_name => :store
      )
      @report.column_hierarchy = :cy
      @report.column_constraints = ['2004','2005','2006']

      @report.row_hierarchy = :region
      @report.row_constraints = ['Northeast','Southeast']
      
      @report.fact_attributes = [:sales_quantity]
      
      @report.column_param_prefix = 'col'
      @report.row_param_prefix = 'row'
      
      @report.format[:gross_margin] = Proc.new {|value| sprintf("%.2f", value) }
    end
    @report
  end
end