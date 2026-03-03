class MessageSender
  attr_reader :message, :error

  def initialize(message, anonymous: false)
    @message = message
    @anonymous = anonymous
    @error = nil
  end

  def deliver
    identity = Identity.instance

    message_json = {
      id: message.didcomm_id,
      typ: "application/didcomm-plain+json",
      type: message.message_type,
      to: [message.to_did],
      created_time: message.created_at.to_i,
      body: message.body_parsed
    }
    message_json[:from] = Identity.did unless @anonymous

    # Step 1: Resolve target DID
    target_did_doc = DidcommService.resolve_did(message.to_did)

    # Step 2: Pack the message
    result = if @anonymous
      DidcommService.pack_anon(
        message_json,
        to: message.to_did,
        did_docs: [target_did_doc]
      )
    else
      DidcommService.pack_encrypted(
        message_json,
        to: message.to_did,
        from: Identity.did,
        did_docs: [identity.did_document, target_did_doc],
        secrets: identity.secrets
      )
    end
    packed = result["packedMessage"]
    message.update!(packed_message: packed)

    # Step 3: Find endpoint and send
    endpoint = extract_service_endpoint(target_did_doc)

    unless endpoint
      message.update!(status: "failed", error_message: "No DIDCommMessaging service endpoint found")
      return false
    end

    response = HTTP.timeout(connect: 10, read: 30)
      .headers("Content-Type" => "application/didcomm-encrypted+json")
      .post(endpoint, body: packed)

    if response.status.success?
      message.update!(status: "delivered", error_message: nil)
      true
    else
      message.update!(status: "failed", error_message: "HTTP #{response.status}: #{response.to_s.truncate(500)}")
      false
    end
  rescue => e
    @error = e
    message.update!(status: "failed", error_message: "#{e.class}: #{e.message}")
    false
  end

  private

  def extract_service_endpoint(did_doc)
    services = did_doc["service"] || []
    svc = services.find { |s| s["type"] == "DIDCommMessaging" }
    return nil unless svc
    ep = svc["serviceEndpoint"]
    ep.is_a?(Hash) ? ep["uri"] : ep
  end
end
