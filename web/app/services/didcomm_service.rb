class DidcommService
  BASE_URL = ENV.fetch("DIDCOMM_SERVICE_URL", "http://didcomm:3000")

  def self.pack_encrypted(message, to:, from:, did_docs:, secrets:)
    post("/didcomm/pack/encrypted", {
      message: message,
      to: to,
      from: from,
      options: { forward: false },
      didDocs: did_docs,
      secrets: secrets
    })
  end

  def self.unpack(packed_message, did_docs:, secrets:)
    post("/didcomm/unpack", {
      message: packed_message,
      didDocs: did_docs,
      secrets: secrets
    })
  end

  def self.resolve_did(did)
    result = post("/did/resolve", { did: did })
    result["didDocument"]
  end

  def self.post(path, body)
    response = HTTP.timeout(connect: 10, read: 30)
      .post("#{BASE_URL}#{path}", json: body)

    parsed = response.parse

    unless response.status.success?
      raise "DIDComm service error: #{parsed["error"] || response.status}"
    end

    parsed
  end
end
