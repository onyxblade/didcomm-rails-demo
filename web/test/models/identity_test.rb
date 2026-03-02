require "test_helper"

class IdentityTest < ActiveSupport::TestCase
  test "validates presence of domain and did" do
    identity = Identity.new
    assert_not identity.valid?
    assert_includes identity.errors[:domain], "can't be blank"
    assert_includes identity.errors[:did], "can't be blank"
  end

  test "generate_keys! populates all key fields" do
    identity = Identity.new(domain: "example.com", did: "did:web:example.com")
    identity.generate_keys!

    assert_not_nil identity.ed25519_public_jwk
    assert_not_nil identity.ed25519_private_jwk
    assert_not_nil identity.x25519_public_jwk
    assert_not_nil identity.x25519_private_jwk

    ed_pub = JSON.parse(identity.ed25519_public_jwk)
    assert_equal "OKP", ed_pub["kty"]
    assert_equal "Ed25519", ed_pub["crv"]
    assert ed_pub.key?("x")
    assert_not ed_pub.key?("d")

    ed_priv = JSON.parse(identity.ed25519_private_jwk)
    assert ed_priv.key?("d")

    x_pub = JSON.parse(identity.x25519_public_jwk)
    assert_equal "OKP", x_pub["kty"]
    assert_equal "X25519", x_pub["crv"]
  end

  test "did_document returns correct structure" do
    identity = identities(:one)
    doc = identity.did_document

    assert_equal identity.did, doc[:id]
    assert_includes doc[:keyAgreement], "#{identity.did}#key-x25519-1"
    assert_includes doc[:authentication], "#{identity.did}#key-ed25519-1"
    assert_equal 2, doc[:verificationMethod].length
    assert_equal 1, doc[:service].length
    assert_equal "DIDCommMessaging", doc[:service][0][:type]
  end

  test "secrets returns two secret entries with private keys" do
    identity = identities(:one)
    secrets = identity.secrets

    assert_equal 2, secrets.length
    assert secrets.all? { |s| s[:type] == "JsonWebKey2020" }
    assert secrets.all? { |s| s[:privateKeyJwk].key?("d") }
  end

  test "instance returns first identity" do
    identity = identities(:one)
    assert_equal identity, Identity.instance
  end

  test "instance raises NotConfiguredError when no identity exists" do
    Identity.delete_all
    assert_raises(Identity::NotConfiguredError) { Identity.instance }
  end
end
