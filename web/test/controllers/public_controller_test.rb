require "test_helper"

class PublicControllerTest < ActionDispatch::IntegrationTest
  test "GET / shows landing page" do
    get root_path
    assert_response :success
    assert_match "DIDComm Rails Demo", response.body
  end

  test "GET / does not show messages" do
    get root_path
    assert_no_match "Hello", response.body
    assert_no_match "Hi back", response.body
  end
end
