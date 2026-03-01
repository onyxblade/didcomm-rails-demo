# DIDComm HTTP Service

A Docker image that wraps [didcomm-rust](https://github.com/sicpa-dlab/didcomm-rust) (the DIDComm v2 reference implementation) as an HTTP service, making it easy for Ruby, Python, and other languages to call DIDComm encryption, signing, and decryption operations over HTTP.

Under the hood it uses the didcomm-rust WASM bindings ([didcomm-node](https://www.npmjs.com/package/didcomm-node)) with an Express HTTP layer on top.

## Quick Start

```bash
# Build the image
docker build -t didcomm-http .

# Run (port 3000)
docker run -p 3000:3000 didcomm-http

# Health check
curl http://localhost:3000/health
# => {"status":"ok"}

# Run tests
./test.sh http://localhost:3000
```

Run without Docker:

```bash
npm install
node server.js
```

## Project Structure

```
server.js        # HTTP service (~120 lines)
package.json     # Dependencies: express + didcomm-node
Dockerfile       # Node 20 Alpine image
test.sh          # Test script (10 test cases)
```

## Design Principles

- **Stateless**: DID Documents and secrets are passed in with each request; the service stores nothing
- **Minimal code**: Core service is only ~120 lines
- **Full-featured**: Supports all DIDComm v2 operations (encrypt, sign, plaintext, decrypt, forward routing)

---

## API Reference

Base URL: `http://localhost:3000`

All endpoints are stateless. DID Documents and secrets must be provided with each request.

## Common Data Structures

### Message

```json
{
  "id": "unique-message-id",
  "typ": "application/didcomm-plain+json",
  "type": "http://example.com/protocols/test/1.0/msg",
  "from": "did:example:alice",
  "to": ["did:example:bob"],
  "body": { "key": "value" },
  "created_time": 1516269022,
  "expires_time": 1516385931,
  "thid": "thread-id",
  "pthid": "parent-thread-id",
  "attachments": []
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | string | Yes | Unique message identifier |
| typ | string | Yes | Fixed value `"application/didcomm-plain+json"` |
| type | string | Yes | Protocol message type URI |
| body | object | Yes | Message body content |
| from | string | No | Sender DID |
| to | string[] | No | Recipient DID list |
| created_time | number | No | Creation time (Unix seconds) |
| expires_time | number | No | Expiration time (Unix seconds) |
| thid | string | No | Thread ID |
| pthid | string | No | Parent thread ID |
| attachments | array | No | Attachment list |

### DIDDoc

```json
{
  "id": "did:example:alice",
  "keyAgreement": ["did:example:alice#key-x25519-1"],
  "authentication": ["did:example:alice#key-1"],
  "verificationMethod": [
    {
      "id": "did:example:alice#key-x25519-1",
      "type": "JsonWebKey2020",
      "controller": "did:example:alice#key-x25519-1",
      "publicKeyJwk": {
        "crv": "X25519",
        "kty": "OKP",
        "x": "avH0O2Y4tqLAq8y9zpianr8ajii5m4F_mICrzNlatXs"
      }
    }
  ],
  "service": []
}
```

| Field | Type | Description |
|-------|------|-------------|
| id | string | DID identifier |
| keyAgreement | string[] | Key IDs used for encryption |
| authentication | string[] | Key IDs used for signing |
| verificationMethod | array | Verification methods (public keys) |
| service | array | Service endpoints |

### Secret

```json
{
  "id": "did:example:alice#key-x25519-1",
  "type": "JsonWebKey2020",
  "privateKeyJwk": {
    "crv": "X25519",
    "d": "r-jK2cO3taR8LQnJB1_ikLBTAnOtShJOsHXRUWT-aZA",
    "kty": "OKP",
    "x": "avH0O2Y4tqLAq8y9zpianr8ajii5m4F_mICrzNlatXs"
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| id | string | Key ID (corresponds to verificationMethod.id in DIDDoc) |
| type | string | Key type, e.g. `JsonWebKey2020` |
| privateKeyJwk | object | Private key in JWK format |

---

## Endpoints

### GET /health

Health check.

**Response**

```json
{ "status": "ok" }
```

---

### POST /pack/encrypted

Encrypt a message. Supports authenticated encryption (authcrypt) and anonymous encryption (anoncrypt).

**Request Body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| message | Message | Yes | The message to encrypt |
| to | string | Yes | Recipient DID or DID URL |
| from | string | No | Sender DID (null for anonymous encryption) |
| sign_by | string | No | Signer DID (enables non-repudiation when provided) |
| did_docs | DIDDoc[] | Yes | Related DID Documents |
| secrets | Secret[] | Yes | Sender's private keys |
| options | object | No | Encryption options |

**options**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| forward | boolean | true | Whether to auto-wrap in Forward messages |
| protect_sender | boolean | true | Whether to protect sender identity |
| enc_alg_auth | string | `"A256cbcHs512Ecdh1puA256kw"` | Authenticated encryption algorithm |
| enc_alg_anon | string | `"Xc20pEcdhEsA256kw"` | Anonymous encryption algorithm |

**Response**

```json
{
  "packed_message": "<JWE JSON string>",
  "metadata": {
    "messaging_service": null,
    "from_kid": "did:example:alice#key-x25519-1",
    "sign_by_kid": null,
    "to_kids": ["did:example:bob#key-x25519-1"]
  }
}
```

**curl example -- authenticated encryption**

```bash
curl -X POST http://localhost:3000/pack/encrypted \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "id": "msg-1",
      "typ": "application/didcomm-plain+json",
      "type": "http://example.com/protocols/test/1.0/msg",
      "from": "did:example:alice",
      "to": ["did:example:bob"],
      "body": {"hello": "world"}
    },
    "to": "did:example:bob",
    "from": "did:example:alice",
    "options": {"forward": false},
    "did_docs": [
      {"id":"did:example:alice","keyAgreement":["did:example:alice#key-x25519-1"],"authentication":["did:example:alice#key-1"],"verificationMethod":[{"id":"did:example:alice#key-x25519-1","type":"JsonWebKey2020","controller":"did:example:alice#key-x25519-1","publicKeyJwk":{"crv":"X25519","kty":"OKP","x":"avH0O2Y4tqLAq8y9zpianr8ajii5m4F_mICrzNlatXs"}},{"id":"did:example:alice#key-1","type":"JsonWebKey2020","controller":"did:example:alice#key-1","publicKeyJwk":{"crv":"Ed25519","kty":"OKP","x":"G-boxFB6vOZBu-wXkm-9Lh79I8nf9Z50cILaOgKKGww"}}],"service":[]},
      {"id":"did:example:bob","keyAgreement":["did:example:bob#key-x25519-1"],"authentication":[],"verificationMethod":[{"id":"did:example:bob#key-x25519-1","type":"JsonWebKey2020","controller":"did:example:bob#key-x25519-1","publicKeyJwk":{"crv":"X25519","kty":"OKP","x":"GDTrI66K0pFfO54tlCSvfjjNapIs44dzpneBgyx0S3E"}}],"service":[]}
    ],
    "secrets": [
      {"id":"did:example:alice#key-x25519-1","type":"JsonWebKey2020","privateKeyJwk":{"crv":"X25519","d":"r-jK2cO3taR8LQnJB1_ikLBTAnOtShJOsHXRUWT-aZA","kty":"OKP","x":"avH0O2Y4tqLAq8y9zpianr8ajii5m4F_mICrzNlatXs"}}
    ]
  }'
```

**curl example -- anonymous encryption (from is null)**

```bash
curl -X POST http://localhost:3000/pack/encrypted \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "id": "msg-anon",
      "typ": "application/didcomm-plain+json",
      "type": "http://example.com/protocols/test/1.0/msg",
      "from": "did:example:alice",
      "to": ["did:example:bob"],
      "body": {"anonymous": true}
    },
    "to": "did:example:bob",
    "from": null,
    "options": {"forward": false},
    "did_docs": [<alice_did_doc>, <bob_did_doc>],
    "secrets": []
  }'
```

---

### POST /pack/signed

Sign a message without encryption. Used for non-repudiation scenarios.

**Request Body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| message | Message | Yes | The message to sign |
| sign_by | string | Yes | Signer DID or DID URL |
| did_docs | DIDDoc[] | Yes | Related DID Documents |
| secrets | Secret[] | Yes | Signer's private keys (authentication type) |

**Response**

```json
{
  "packed_message": "<JWS JSON string>",
  "metadata": {
    "sign_by_kid": "did:example:alice#key-1"
  }
}
```

**curl example**

```bash
curl -X POST http://localhost:3000/pack/signed \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "id": "msg-signed",
      "typ": "application/didcomm-plain+json",
      "type": "http://example.com/protocols/test/1.0/msg",
      "from": "did:example:alice",
      "to": ["did:example:bob"],
      "body": {"signed": "data"}
    },
    "sign_by": "did:example:alice",
    "did_docs": [<alice_did_doc>],
    "secrets": [
      {"id":"did:example:alice#key-1","type":"JsonWebKey2020","privateKeyJwk":{"crv":"Ed25519","d":"pFRUKkyzx4kHdJtFSnlPA9WzqkDT1HWV0xZ5OYZd2SY","kty":"OKP","x":"G-boxFB6vOZBu-wXkm-9Lh79I8nf9Z50cILaOgKKGww"}}
    ]
  }'
```

---

### POST /pack/plaintext

Pack a message as plaintext JSON (no encryption, no signing). For local use or debugging only.

**Request Body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| message | Message | Yes | The message to pack |
| did_docs | DIDDoc[] | Yes | Related DID Documents |

**Response**

```json
{
  "packed_message": "<plaintext JSON string>"
}
```

**curl example**

```bash
curl -X POST http://localhost:3000/pack/plaintext \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "id": "msg-plain",
      "typ": "application/didcomm-plain+json",
      "type": "http://example.com/protocols/test/1.0/msg",
      "from": "did:example:alice",
      "to": ["did:example:bob"],
      "body": {"plain": "text"}
    },
    "did_docs": [<alice_did_doc>]
  }'
```

---

### POST /unpack

Unpack a message (auto-detects encrypted/signed/plaintext format).

**Request Body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| packed_message | string | Yes | The packed message string |
| did_docs | DIDDoc[] | Yes | Related DID Documents |
| secrets | Secret[] | Yes | Recipient's private keys |
| options | object | No | Unpack options |

**Response**

```json
{
  "message": {
    "id": "msg-1",
    "typ": "application/didcomm-plain+json",
    "type": "http://example.com/protocols/test/1.0/msg",
    "from": "did:example:alice",
    "to": ["did:example:bob"],
    "body": {"hello": "world"}
  },
  "metadata": {
    "encrypted": true,
    "authenticated": true,
    "non_repudiation": false,
    "anonymous_sender": false,
    "re_wrapped_in_forward": false,
    "encrypted_from_kid": "did:example:alice#key-x25519-1",
    "encrypted_to_kids": ["did:example:bob#key-x25519-1"],
    "sign_from": null,
    "enc_alg_auth": "A256cbcHs512Ecdh1puA256kw",
    "enc_alg_anon": null,
    "sign_alg": null,
    "signed_message": null,
    "from_prior": null,
    "from_prior_issuer_kid": null
  }
}
```

**Metadata fields**

| Field | Type | Description |
|-------|------|-------------|
| encrypted | boolean | Whether the message was encrypted |
| authenticated | boolean | Whether the sender was authenticated |
| non_repudiation | boolean | Whether non-repudiation is provided |
| anonymous_sender | boolean | Whether the sender is anonymous |
| re_wrapped_in_forward | boolean | Whether the message was re-wrapped in a Forward |
| encrypted_from_kid | string | Sender key ID used for encryption |
| encrypted_to_kids | string[] | Recipient key IDs used for encryption |
| sign_from | string | Signer key ID |
| enc_alg_auth | string | Authenticated encryption algorithm |
| enc_alg_anon | string | Anonymous encryption algorithm |
| sign_alg | string | Signing algorithm |

---

### POST /forward/wrap

Wrap a packed message in a Forward message (for routing through mediators).

**Request Body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| packed_message | string | Yes | The packed message string |
| to | string | Yes | Final recipient DID |
| routing_keys | string[] | Yes | Routing key ID list |
| did_docs | DIDDoc[] | Yes | Related DID Documents |
| headers | object | No | Extra headers for the Forward message |
| enc_alg_anon | string | No | Anonymous encryption algorithm (default `"A256cbcHs512EcdhEsA256kw"`) |

**Response**

```json
{
  "packed_message": "<Forward JWE JSON string>"
}
```

---

## Error Responses

All endpoints return HTTP 400 on error:

```json
{
  "error": "error message description"
}
```

Common error types:

| Error | Description |
|-------|-------------|
| DIDCommDIDNotResolved | DID could not be resolved (missing from did_docs) |
| DIDCommDIDUrlNotFound | DID URL (key ID) not found in DID Document |
| DIDCommSecretNotFound | Required private key not found in secrets |
| DIDCommMalformed | Malformed message format |
| DIDCommNoCompatibleCrypto | No compatible crypto between sender and recipient |

---

## Supported Algorithms

**Key agreement curves**: X25519, P-256

**Content encryption**: XC20P, A256GCM, A256CBC-HS512

**Key wrapping**: ECDH-ES+A256KW (anonymous), ECDH-1PU+A256KW (authenticated)

**Signing curves**: Ed25519, P-256, secp256k1

**Signing algorithms**: EdDSA, ES256, ES256K

---

## Ruby Example

```ruby
require 'net/http'
require 'json'
require 'uri'

BASE_URL = 'http://localhost:3000'

# --- Define DID Documents and keys ---

alice_did_doc = {
  id: 'did:example:alice',
  keyAgreement: ['did:example:alice#key-x25519-1'],
  authentication: ['did:example:alice#key-1'],
  verificationMethod: [
    { id: 'did:example:alice#key-x25519-1', type: 'JsonWebKey2020',
      controller: 'did:example:alice#key-x25519-1',
      publicKeyJwk: { crv: 'X25519', kty: 'OKP',
        x: 'avH0O2Y4tqLAq8y9zpianr8ajii5m4F_mICrzNlatXs' } },
    { id: 'did:example:alice#key-1', type: 'JsonWebKey2020',
      controller: 'did:example:alice#key-1',
      publicKeyJwk: { crv: 'Ed25519', kty: 'OKP',
        x: 'G-boxFB6vOZBu-wXkm-9Lh79I8nf9Z50cILaOgKKGww' } }
  ],
  service: []
}

bob_did_doc = {
  id: 'did:example:bob',
  keyAgreement: ['did:example:bob#key-x25519-1'],
  authentication: [],
  verificationMethod: [
    { id: 'did:example:bob#key-x25519-1', type: 'JsonWebKey2020',
      controller: 'did:example:bob#key-x25519-1',
      publicKeyJwk: { crv: 'X25519', kty: 'OKP',
        x: 'GDTrI66K0pFfO54tlCSvfjjNapIs44dzpneBgyx0S3E' } }
  ],
  service: []
}

alice_secrets = [
  { id: 'did:example:alice#key-x25519-1', type: 'JsonWebKey2020',
    privateKeyJwk: { crv: 'X25519',
      d: 'r-jK2cO3taR8LQnJB1_ikLBTAnOtShJOsHXRUWT-aZA',
      kty: 'OKP',
      x: 'avH0O2Y4tqLAq8y9zpianr8ajii5m4F_mICrzNlatXs' } }
]

bob_secrets = [
  { id: 'did:example:bob#key-x25519-1', type: 'JsonWebKey2020',
    privateKeyJwk: { crv: 'X25519',
      d: 'b9NnuOCB0hm7YGNvaE9DMhwH_wjZA1-gWD6dA0JWdL0',
      kty: 'OKP',
      x: 'GDTrI66K0pFfO54tlCSvfjjNapIs44dzpneBgyx0S3E' } }
]

# --- Alice encrypts a message for Bob ---

encrypt_res = Net::HTTP.post(
  URI("#{BASE_URL}/pack/encrypted"),
  {
    message: {
      id: 'ruby-msg-1',
      typ: 'application/didcomm-plain+json',
      type: 'http://example.com/protocols/test/1.0/msg',
      from: 'did:example:alice',
      to: ['did:example:bob'],
      body: { greeting: 'Hello from Ruby!' }
    },
    to: 'did:example:bob',
    from: 'did:example:alice',
    options: { forward: false },
    did_docs: [alice_did_doc, bob_did_doc],
    secrets: alice_secrets
  }.to_json,
  'Content-Type' => 'application/json'
)

packed = JSON.parse(encrypt_res.body)
puts "Encrypted message: #{packed['packed_message'][0..80]}..."

# --- Bob decrypts the message ---

unpack_res = Net::HTTP.post(
  URI("#{BASE_URL}/unpack"),
  {
    packed_message: packed['packed_message'],
    did_docs: [alice_did_doc, bob_did_doc],
    secrets: bob_secrets
  }.to_json,
  'Content-Type' => 'application/json'
)

result = JSON.parse(unpack_res.body)
puts "Decrypted body: #{result['message']['body']}"
puts "Authenticated: #{result['metadata']['authenticated']}"
```
