require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "validates direction inclusion" do
    msg = Message.new(direction: "invalid", status: "sent")
    assert_not msg.valid?
    assert_includes msg.errors[:direction], "is not included in the list"
  end

  test "validates status inclusion" do
    msg = Message.new(direction: "sent", status: "invalid")
    assert_not msg.valid?
    assert_includes msg.errors[:status], "is not included in the list"
  end

  test "scopes filter correctly" do
    assert_includes Message.sent, messages(:sent_one)
    assert_not_includes Message.sent, messages(:received_one)

    assert_includes Message.received, messages(:received_one)
    assert_not_includes Message.received, messages(:sent_one)
  end

  test "body_parsed returns parsed JSON" do
    msg = messages(:sent_one)
    assert_equal({ "content" => "Hello" }, msg.body_parsed)
  end

  test "body_parsed returns raw string for invalid JSON" do
    msg = Message.new(body: "not json")
    assert_equal "not json", msg.body_parsed
  end
end
