require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "GET /login renders form" do
    get login_path
    assert_response :success
    assert_select "input[name='username']"
  end

  test "POST /login with valid credentials logs in" do
    post login_path, params: { username: "admin", password: "password123" }
    assert_redirected_to messages_path
    follow_redirect!
    assert_response :success
  end

  test "POST /login with invalid credentials shows error" do
    post login_path, params: { username: "admin", password: "wrong" }
    assert_response :unprocessable_entity
  end

  test "DELETE /logout clears session" do
    post login_path, params: { username: "admin", password: "password123" }
    delete logout_path
    assert_redirected_to root_path

    get messages_path
    assert_redirected_to login_path
  end
end
