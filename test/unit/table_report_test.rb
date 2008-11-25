require "#{File.dirname(__FILE__)}/../test_helper"

class TableReportTest < Test::Unit::TestCase
  context "a TableReport" do
    context "instantiated with only a cube name" do
      setup do
        @report = ActiveWarehouse::Report::TableReport.new('sales', 'store', 'date')
      end
      should "return an empty hash by default from the format method" do
        assert_equal({}, @report.format)
      end
      should "return false by default from the link_cell method" do
        assert !@report.link_cell
      end
      should "return an empty hash by default from the html_params method" do
        assert_equal({}, @report.html_params)
      end
      should "return a TableView from the view method" do
        v = @report.view
        assert_equal ActiveWarehouse::View::TableView, v.class
      end
    end
  end
end