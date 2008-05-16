require File.dirname(__FILE__) + '/../test_helper'
require 'revision_reports_controller'

# Re-raise errors caught by the controller.
class RevisionReportsController; def rescue_action(e) raise e end; end

class RevisionReportsControllerTest < Test::Unit::TestCase
  def setup
    @controller = RevisionReportsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
