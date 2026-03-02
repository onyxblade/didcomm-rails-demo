class MessageSender
  attr_reader :message, :error

  def initialize(message)
    @message = message
    @error = nil
  end

  def deliver
    identity = Identity.instance

    message_json = {
      id: message.didcomm_id,
      typ: "application/didcomm-plain+json",
      type: message.message_type,
      from: identity.did,
      to: [message.to_did],
      created_time: message.created_at.to_i,
      body: message.body_parsed
    }

    # Step 1: Resolve target DID
    target_did_doc = DidResolverService.resolve(message.to_did)

    # Step 2: Pack the message
    result = DidcommService.pack_encrypted(
      message_json,
      to: message.to_did,
      from: identity.did,
      did_docs: [identity.did_document, target_did_doc],
      secrets: identity.secrets
    )
    packed = result["packed_message"]
    message.update!(packed_message: packed)

    # Step 3: Find endpoint and send
    endpoint = extract_service_endpoint(target_did_doc)

    unless endpoint
      message.update!(status: "failed", error_message: "No DIDCommMessaging service endpoint found")
      return false
    end

    uri = URI(endpoint)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 30
    req = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/didcomm-encrypted+json")
    req.body = packed
    response = http.request(req)

    if response.is_a?(Net::HTTPSuccess)
      message.update!(status: "delivered", error_message: nil)
      true
    else
      message.update!(status: "failed", error_message: "HTTP #{response.code}: #{response.body.truncate(500)}")
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
