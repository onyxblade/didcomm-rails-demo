class MessagesController < ApplicationController
  before_action :require_login

  def index
    @messages = Message.order(created_at: :desc)
  end

  def show
    @message = Message.find(params[:id])
  end

  def new
  end

  def create
    identity = Identity.instance
    to_did = params[:to_did].strip
    body_content = params[:body].strip
    visibility = params[:visibility] || "private"

    body_hash = begin
      JSON.parse(body_content)
    rescue JSON::ParserError
      { "content" => body_content }
    end

    didcomm_id = SecureRandom.uuid

    message_json = {
      id: didcomm_id,
      typ: "application/didcomm-plain+json",
      type: "https://didcomm.org/basicmessage/2.0/message",
      from: identity.did,
      to: [to_did],
      created_time: Time.now.to_i,
      body: body_hash
    }

    begin
      # Resolve the target DID document
      target_did_doc = DidResolverService.resolve(to_did)

      # Pack the message
      our_did_doc = identity.did_document
      result = DidcommService.pack_encrypted(
        message_json,
        to: to_did,
        from: identity.did,
        did_docs: [our_did_doc, target_did_doc],
        secrets: identity.secrets
      )
      packed = result["packed_message"]

      # Find service endpoint from target DID doc
      endpoint = extract_service_endpoint(target_did_doc)

      # Send to target
      status = "failed"
      if endpoint
        uri = URI(endpoint)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = 10
        http.read_timeout = 30
        req = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/didcomm-encrypted+json")
        req.body = packed
        response = http.request(req)
        status = response.is_a?(Net::HTTPSuccess) ? "delivered" : "failed"
      else
        status = "sent"
      end

      Message.create!(
        didcomm_id: didcomm_id,
        direction: "sent",
        from_did: identity.did,
        to_did: to_did,
        message_type: message_json[:type],
        body: body_hash.to_json,
        packed_message: packed,
        visibility: visibility,
        status: status
      )

      redirect_to messages_path, notice: "Message #{status}."
    rescue => e
      Message.create!(
        didcomm_id: didcomm_id,
        direction: "sent",
        from_did: identity.did,
        to_did: to_did,
        message_type: message_json[:type],
        body: body_hash.to_json,
        visibility: visibility,
        status: "failed"
      )

      redirect_to messages_path, alert: "Failed to send: #{e.message}"
    end
  end

  private

  def extract_service_endpoint(did_doc)
    services = did_doc["service"] || did_doc[:service] || []
    svc = services.find { |s| s["type"] == "DIDCommMessaging" || s[:type] == "DIDCommMessaging" }
    svc && (svc["serviceEndpoint"] || svc[:serviceEndpoint])
  end
end
