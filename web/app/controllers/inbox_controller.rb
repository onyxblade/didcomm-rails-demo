class InboxController < ApplicationController
  skip_forgery_protection

  def create
    identity = Identity.instance

    packed_message = request.raw_post

    result = DidcommService.unpack(
      packed_message,
      did_docs: [identity.did_document],
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
      visibility: "private",
      status: "delivered"
    )

    render json: { status: "ok" }, status: :ok
  rescue Identity::NotConfiguredError
    render json: { error: "Not configured" }, status: :service_unavailable
  rescue => e
    Rails.logger.error("Inbox error: #{e.message}")
    render json: { error: e.message }, status: :bad_request
  end
end
