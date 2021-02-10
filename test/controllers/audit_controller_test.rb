require 'test_helper'

class AuditControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get audit_index_url
    assert_response :success
  end

end
