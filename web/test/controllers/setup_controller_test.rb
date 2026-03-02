require "test_helper"

class SetupControllerTest < ActionDispatch::IntegrationTest
  test "GET /setup renders form when no admin exists" do
    Admin.delete_all
    get setup_path
    assert_response :success
    assert_select "input[name='username']"
  end

  test "GET /setup redirects when admin already exists" do
    get setup_path
    assert_redirected_to root_path
  end

  test "POST /setup creates admin and identity" do
    Admin.delete_all
    Identity.delete_all

    post setup_path, params: {
      username: "newadmin",
      password: "password123",
      password_confirmation: "password123"
    }

    assert_equal 1, Admin.count
    assert_equal 1, Identity.count
    assert_equal "newadmin", Admin.first.username
    assert Identity.first.did.start_with?("did:web:")
    assert_redirected_to messages_path
  end

  test "POST /setup rejects mismatched passwords" do
    Admin.delete_all
    Identity.delete_all

    post setup_path, params: {
      username: "newadmin",
      password: "password123",
      password_confirmation: "different"
    }

    assert_response :unprocessable_entity
    assert_equal 0, Admin.count
  end
end
