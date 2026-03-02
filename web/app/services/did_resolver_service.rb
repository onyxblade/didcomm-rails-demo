require "net/http"
require "cgi"

class DidResolverService
  BASE_URL = ENV.fetch("RESOLVER_URL", "http://uni-resolver-web:8080")

  def self.resolve(did)
    uri = URI("#{BASE_URL}/1.0/identifiers/#{CGI.escape(did)}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 10
    http.read_timeout = 30

    response = http.get(uri.request_uri, "Accept" => "application/json")

    unless response.is_a?(Net::HTTPSuccess)
      raise "DID resolution failed for #{did}: HTTP #{response.code}"
    end

    parsed = JSON.parse(response.body)
    did_document = parsed["didDocument"]

    unless did_document
      raise "DID resolution returned no document for #{did}"
    end

    did_document
  end
end
