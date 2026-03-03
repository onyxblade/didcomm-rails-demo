require "test_helper"

class InboxControllerTest < ActionDispatch::IntegrationTest
  test "POST /didcomm auto-creates identity if missing" do
    Identity.delete_all
    post didcomm_path, params: "test", headers: { "CONTENT_TYPE" => "application/didcomm-encrypted+json" }
    assert_equal 1, Identity.count
  end
end
