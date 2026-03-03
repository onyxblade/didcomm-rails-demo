require "test_helper"

class DidControllerTest < ActionDispatch::IntegrationTest
  test "GET /.well-known/did.json returns DID document" do
    get "/.well-known/did.json"
    assert_response :success

    doc = JSON.parse(response.body)
    assert_equal Identity.did, doc["id"]
    assert doc.key?("keyAgreement")
    assert doc.key?("authentication")
    assert doc.key?("verificationMethod")
    assert doc.key?("service")
  end

  test "GET /.well-known/did.json auto-creates identity if missing" do
    Identity.delete_all
    get "/.well-known/did.json"
    assert_response :success
    assert_equal 1, Identity.count
  end
end
