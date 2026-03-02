require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "validates direction inclusion" do
    msg = Message.new(direction: "invalid", visibility: "private", status: "sent")
    assert_not msg.valid?
    assert_includes msg.errors[:direction], "is not included in the list"
  end

  test "validates visibility inclusion" do
    msg = Message.new(direction: "sent", visibility: "invalid", status: "sent")
    assert_not msg.valid?
    assert_includes msg.errors[:visibility], "is not included in the list"
  end

  test "validates status inclusion" do
    msg = Message.new(direction: "sent", visibility: "private", status: "invalid")
    assert_not msg.valid?
    assert_includes msg.errors[:status], "is not included in the list"
  end

  test "scopes filter correctly" do
    assert_includes Message.sent, messages(:sent_public)
    assert_not_includes Message.sent, messages(:received_private)

    assert_includes Message.received, messages(:received_private)
    assert_not_includes Message.received, messages(:sent_public)

    assert_includes Message.visible, messages(:sent_public)
    assert_not_includes Message.visible, messages(:received_private)
  end

  test "body_parsed returns parsed JSON" do
    msg = messages(:sent_public)
    assert_equal({ "content" => "Hello" }, msg.body_parsed)
  end

  test "body_parsed returns raw string for invalid JSON" do
    msg = Message.new(body: "not json")
    assert_equal "not json", msg.body_parsed
  end
end
