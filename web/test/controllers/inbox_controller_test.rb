require "test_helper"

class InboxControllerTest < ActionDispatch::IntegrationTest
  test "POST /didcomm returns 503 when no identity configured" do
    Identity.delete_all
    post didcomm_path, params: "test", headers: { "CONTENT_TYPE" => "application/didcomm-encrypted+json" }
    assert_response :service_unavailable
  end
end
