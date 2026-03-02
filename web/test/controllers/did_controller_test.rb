require "test_helper"

class DidControllerTest < ActionDispatch::IntegrationTest
  test "GET /.well-known/did.json returns DID document" do
    get "/.well-known/did.json"
    assert_response :success

    doc = JSON.parse(response.body)
    assert_equal identities(:one).did, doc["id"]
    assert doc.key?("keyAgreement")
    assert doc.key?("authentication")
    assert doc.key?("verificationMethod")
    assert doc.key?("service")
  end

  test "GET /.well-known/did.json returns 404 when no identity" do
    Identity.delete_all
    get "/.well-known/did.json"
    assert_response :not_found
  end
end
