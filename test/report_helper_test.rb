require "#{File.dirname(__FILE__)}/test_helper"

class ReportHelperTest < Test::Unit::TestCase
  include ReportHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TagHelper
  
  class RequestMock
    attr_reader :params
    def initialize(params={})
      @params = params
    end
  end
  
  def setup
    @request = RequestMock.new
  end
  
  def request
    @request
  end
  
  def params
    request.params
  end
  
  def link_to_if(*args)
    condition = args.shift
    value = args.shift
  end
  
  def test_render_report
#    report = ActiveWarehouse::Report::TableReport.new(
#      :cube_name => :regional_sales, 
#      :column_dimension_name => :date,
#      :row_dimension_name => :store
#    )
#    result = render_report(report)
#    # TODO: implement this test
#    #assert_equal "", result 
  end
end