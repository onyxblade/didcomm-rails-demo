require "test_helper"

class PublicControllerTest < ActionDispatch::IntegrationTest
  test "GET / shows public messages" do
    get root_path
    assert_response :success
    assert_match "Hello", response.body
  end

  test "GET / does not show private messages" do
    get root_path
    assert_no_match "Hi back", response.body
  end
end
