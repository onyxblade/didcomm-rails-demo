require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_path, params: { password: ENV["ADMIN_PASSWORD"] }
  end

  test "GET /messages requires login" do
    delete logout_path
    get messages_path
    assert_redirected_to login_path
  end

  test "GET /messages lists messages" do
    get messages_path
    assert_response :success
    assert_select "table"
  end

  test "GET /messages/new renders send form" do
    get new_message_path
    assert_response :success
    assert_select "input[name='to_did']"
    assert_select "textarea[name='body']"
  end

  test "GET /messages/:id shows message detail" do
    get message_path(messages(:sent_public))
    assert_response :success
    assert_select "pre", /Hello/
  end
end
