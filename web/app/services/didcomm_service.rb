require "net/http"

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
    uri = URI("#{BASE_URL}/did/resolve/#{CGI.escape(did)}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 10
    http.read_timeout = 30

    response = http.get(uri.request_uri, "Accept" => "application/json")

    parsed = JSON.parse(response.body)

    unless response.is_a?(Net::HTTPSuccess)
      error = parsed.dig("didResolutionMetadata", "error") || response.code
      raise "DID resolution failed for #{did}: #{error}"
    end

    parsed["didDocument"]
  end

  def self.post(path, body)
    uri = URI("#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
    request.body = body.to_json

    response = http.request(request)

    parsed = JSON.parse(response.body)

    unless response.is_a?(Net::HTTPSuccess)
      raise "DIDComm service error: #{parsed["error"] || response.code}"
    end

    parsed
  end
end
