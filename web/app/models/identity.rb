class Identity < ApplicationRecord
  class NotConfiguredError < StandardError
    def initialize = super("Identity not configured. Run setup first.")
  end

  validates :domain, presence: true
  validates :did, presence: true

  def self.instance
    first || raise(NotConfiguredError)
  end

  def generate_keys!
    ed_key = OpenSSL::PKey.generate_key("ED25519")
    x_key = OpenSSL::PKey.generate_key("X25519")

    self.ed25519_public_jwk = ed25519_to_public_jwk(ed_key).to_json
    self.ed25519_private_jwk = ed25519_to_private_jwk(ed_key).to_json
    self.x25519_public_jwk = x25519_to_public_jwk(x_key).to_json
    self.x25519_private_jwk = x25519_to_private_jwk(x_key).to_json
  end

  def did_document
    {
      id: did,
      keyAgreement: ["#{did}#key-x25519-1"],
      authentication: ["#{did}#key-ed25519-1"],
      verificationMethod: [
        {
          id: "#{did}#key-x25519-1",
          type: "JsonWebKey2020",
          controller: "#{did}#key-x25519-1",
          publicKeyJwk: JSON.parse(x25519_public_jwk)
        },
        {
          id: "#{did}#key-ed25519-1",
          type: "JsonWebKey2020",
          controller: "#{did}#key-ed25519-1",
          publicKeyJwk: JSON.parse(ed25519_public_jwk)
        }
      ],
      service: [
        {
          id: "#{did}#didcomm",
          type: "DIDCommMessaging",
          serviceEndpoint: {
            uri: "http://#{domain}/didcomm",
            accept: ["didcomm/v2"],
            routingKeys: []
          }
        }
      ]
    }
  end

  def secrets
    [
      {
        id: "#{did}#key-x25519-1",
        type: "JsonWebKey2020",
        privateKeyJwk: JSON.parse(x25519_private_jwk)
      },
      {
        id: "#{did}#key-ed25519-1",
        type: "JsonWebKey2020",
        privateKeyJwk: JSON.parse(ed25519_private_jwk)
      }
    ]
  end

  private

  def base64url(bytes)
    Base64.urlsafe_encode64(bytes, padding: false)
  end

  def ed25519_to_public_jwk(key)
    raw = key.raw_public_key
    { kty: "OKP", crv: "Ed25519", x: base64url(raw) }
  end

  def ed25519_to_private_jwk(key)
    pub = key.raw_public_key
    priv = key.raw_private_key
    { kty: "OKP", crv: "Ed25519", x: base64url(pub), d: base64url(priv) }
  end

  def x25519_to_public_jwk(key)
    raw = key.raw_public_key
    { kty: "OKP", crv: "X25519", x: base64url(raw) }
  end

  def x25519_to_private_jwk(key)
    pub = key.raw_public_key
    priv = key.raw_private_key
    { kty: "OKP", crv: "X25519", x: base64url(pub), d: base64url(priv) }
  end
end
