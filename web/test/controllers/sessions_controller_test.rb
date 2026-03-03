require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "GET /login renders form" do
    get login_path
    assert_response :success
    assert_select "input[name='password']"
  end

  test "POST /login with valid password logs in" do
    post login_path, params: { password: ENV["ADMIN_PASSWORD"] }
    assert_redirected_to messages_path
    follow_redirect!
    assert_response :success
  end

  test "POST /login with invalid password shows error" do
    post login_path, params: { password: "wrong" }
    assert_response :unprocessable_entity
  end

  test "DELETE /logout clears session" do
    post login_path, params: { password: ENV["ADMIN_PASSWORD"] }
    delete logout_path
    assert_redirected_to root_path

    get messages_path
    assert_redirected_to login_path
  end
end
