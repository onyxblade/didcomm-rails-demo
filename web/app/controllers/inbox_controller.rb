class InboxController < ApplicationController
  skip_forgery_protection

  def create
    identity = Identity.instance

    packed_message = request.raw_post

    # Extract sender DID from JWE protected header and resolve their DID doc
    sender_did = extract_sender_did(packed_message)
    did_docs = [identity.did_document]
    did_docs.unshift(DidcommService.resolve_did(sender_did)) if sender_did

    result = DidcommService.unpack(
      packed_message,
      did_docs: did_docs,
      secrets: identity.secrets
    )

    msg = result["message"]

    Message.create!(
      didcomm_id: msg["id"],
      direction: "received",
      from_did: msg["from"],
      to_did: msg["to"]&.first || identity.did,
      message_type: msg["type"],
      body: (msg["body"] || {}).to_json,
      packed_message: packed_message,
      status: "delivered"
    )

    render json: { status: "ok" }, status: :ok
  rescue Identity::NotConfiguredError
    render json: { error: "Not configured" }, status: :service_unavailable
  rescue => e
    Rails.logger.error("Inbox error: #{e.message}")
    render json: { error: e.message }, status: :bad_request
  end

  private

  def extract_sender_did(packed_message)
    jwe = JSON.parse(packed_message)
    protected_header = JSON.parse(Base64.urlsafe_decode64(jwe["protected"]))
    skid = protected_header["skid"]
    return nil unless skid
    # skid is a key ID like "did:web:example.com#key-1", strip the fragment
    skid.split("#").first
  rescue
    nil
  end
end
