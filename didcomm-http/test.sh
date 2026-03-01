#!/bin/bash
# DIDComm HTTP Service Test Script
# Usage: ./test.sh [base_url]
#   e.g. ./test.sh http://localhost:3000

BASE_URL="${1:-http://localhost:3000}"
PASS=0
FAIL=0

check() {
  local name="$1" condition="$2"
  if [ "$condition" = "true" ]; then
    echo "  PASS: $name"
    ((PASS++))
  else
    echo "  FAIL: $name"
    ((FAIL++))
  fi
}

# --- Shared test data ---

ALICE_DID_DOC='{
  "id":"did:example:alice",
  "keyAgreement":["did:example:alice#key-x25519-1"],
  "authentication":["did:example:alice#key-1"],
  "verificationMethod":[
    {"id":"did:example:alice#key-x25519-1","type":"JsonWebKey2020","controller":"did:example:alice#key-x25519-1",
     "publicKeyJwk":{"crv":"X25519","kty":"OKP","x":"avH0O2Y4tqLAq8y9zpianr8ajii5m4F_mICrzNlatXs"}},
    {"id":"did:example:alice#key-1","type":"JsonWebKey2020","controller":"did:example:alice#key-1",
     "publicKeyJwk":{"crv":"Ed25519","kty":"OKP","x":"G-boxFB6vOZBu-wXkm-9Lh79I8nf9Z50cILaOgKKGww"}}
  ],
  "service":[]
}'

BOB_DID_DOC='{
  "id":"did:example:bob",
  "keyAgreement":["did:example:bob#key-x25519-1"],
  "authentication":[],
  "verificationMethod":[
    {"id":"did:example:bob#key-x25519-1","type":"JsonWebKey2020","controller":"did:example:bob#key-x25519-1",
     "publicKeyJwk":{"crv":"X25519","kty":"OKP","x":"GDTrI66K0pFfO54tlCSvfjjNapIs44dzpneBgyx0S3E"}}
  ],
  "service":[]
}'

ALICE_SECRET_X25519='{"id":"did:example:alice#key-x25519-1","type":"JsonWebKey2020","privateKeyJwk":{"crv":"X25519","d":"r-jK2cO3taR8LQnJB1_ikLBTAnOtShJOsHXRUWT-aZA","kty":"OKP","x":"avH0O2Y4tqLAq8y9zpianr8ajii5m4F_mICrzNlatXs"}}'

ALICE_SECRET_ED25519='{"id":"did:example:alice#key-1","type":"JsonWebKey2020","privateKeyJwk":{"crv":"Ed25519","d":"pFRUKkyzx4kHdJtFSnlPA9WzqkDT1HWV0xZ5OYZd2SY","kty":"OKP","x":"G-boxFB6vOZBu-wXkm-9Lh79I8nf9Z50cILaOgKKGww"}}'

BOB_SECRET_X25519='{"id":"did:example:bob#key-x25519-1","type":"JsonWebKey2020","privateKeyJwk":{"crv":"X25519","d":"b9NnuOCB0hm7YGNvaE9DMhwH_wjZA1-gWD6dA0JWdL0","kty":"OKP","x":"GDTrI66K0pFfO54tlCSvfjjNapIs44dzpneBgyx0S3E"}}'

MSG='{"id":"test-1","typ":"application/didcomm-plain+json","type":"http://example.com/protocols/test/1.0/msg","from":"did:example:alice","to":["did:example:bob"],"body":{"hello":"world"}}'

# ========================================
echo "=== 1. Health Check ==="
HEALTH=$(curl -sf "$BASE_URL/health")
check "GET /health returns ok" "$(echo "$HEALTH" | python3 -c 'import sys,json; print("true" if json.load(sys.stdin).get("status")=="ok" else "false")' 2>/dev/null)"

# ========================================
echo "=== 2. Pack Plaintext ==="
PLAIN=$(curl -sf -X POST "$BASE_URL/pack/plaintext" \
  -H "Content-Type: application/json" \
  -d "{\"message\":$MSG,\"did_docs\":[$ALICE_DID_DOC]}")
HAS_PACKED=$(echo "$PLAIN" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("true" if d.get("packed_message") else "false")' 2>/dev/null)
check "POST /pack/plaintext returns packed_message" "$HAS_PACKED"

PLAIN_BODY=$(echo "$PLAIN" | python3 -c 'import sys,json; pm=json.loads(json.load(sys.stdin)["packed_message"]); print(json.dumps(pm["body"]))' 2>/dev/null)
check "Plaintext body matches original" "$([ "$PLAIN_BODY" = '{"hello": "world"}' ] && echo true || echo false)"

# ========================================
echo "=== 3. Pack Encrypted (Alice -> Bob) ==="
ENCRYPTED=$(curl -sf -X POST "$BASE_URL/pack/encrypted" \
  -H "Content-Type: application/json" \
  -d "{
    \"message\":$MSG,
    \"to\":\"did:example:bob\",
    \"from\":\"did:example:alice\",
    \"options\":{\"forward\":false},
    \"did_docs\":[$ALICE_DID_DOC,$BOB_DID_DOC],
    \"secrets\":[$ALICE_SECRET_X25519]
  }")
ENC_OK=$(echo "$ENCRYPTED" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("true" if d.get("packed_message") and d.get("metadata") else "false")' 2>/dev/null)
check "POST /pack/encrypted returns packed_message + metadata" "$ENC_OK"

# ========================================
echo "=== 4. Unpack (Bob decrypts) ==="
PACKED_MSG=$(echo "$ENCRYPTED" | python3 -c 'import sys,json; print(json.load(sys.stdin)["packed_message"])' 2>/dev/null)

UNPACK_REQ=$(python3 -c "
import json
print(json.dumps({
  'packed_message': '''$PACKED_MSG'''.strip(),
  'did_docs': [json.loads('''$ALICE_DID_DOC'''), json.loads('''$BOB_DID_DOC''')],
  'secrets': [json.loads('''$BOB_SECRET_X25519''')]
}))
" 2>/dev/null)

UNPACKED=$(echo "$UNPACK_REQ" | curl -sf -X POST "$BASE_URL/unpack" \
  -H "Content-Type: application/json" -d @-)

UNPACK_BODY=$(echo "$UNPACKED" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(json.dumps(d["message"]["body"]))' 2>/dev/null)
check "POST /unpack decrypts correctly" "$([ "$UNPACK_BODY" = '{"hello": "world"}' ] && echo true || echo false)"

UNPACK_META=$(echo "$UNPACKED" | python3 -c 'import sys,json; m=json.load(sys.stdin)["metadata"]; print("true" if m["encrypted"] and m["authenticated"] else "false")' 2>/dev/null)
check "Unpack metadata shows encrypted+authenticated" "$UNPACK_META"

# ========================================
echo "=== 5. Pack Signed ==="
SIGNED=$(curl -sf -X POST "$BASE_URL/pack/signed" \
  -H "Content-Type: application/json" \
  -d "{
    \"message\":$MSG,
    \"sign_by\":\"did:example:alice\",
    \"did_docs\":[$ALICE_DID_DOC],
    \"secrets\":[$ALICE_SECRET_ED25519]
  }")
SIGN_OK=$(echo "$SIGNED" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("true" if d.get("packed_message") and d.get("metadata",{}).get("sign_by_kid") else "false")' 2>/dev/null)
check "POST /pack/signed returns packed_message + sign_by_kid" "$SIGN_OK"

# ========================================
echo "=== 6. Unpack Signed Message ==="
SIGNED_MSG=$(echo "$SIGNED" | python3 -c 'import sys,json; print(json.load(sys.stdin)["packed_message"])' 2>/dev/null)

UNPACK_SIGNED_REQ=$(python3 -c "
import json
print(json.dumps({
  'packed_message': '''$SIGNED_MSG'''.strip(),
  'did_docs': [json.loads('''$ALICE_DID_DOC'''), json.loads('''$BOB_DID_DOC''')],
  'secrets': [json.loads('''$BOB_SECRET_X25519''')]
}))
" 2>/dev/null)

UNPACKED_SIGNED=$(echo "$UNPACK_SIGNED_REQ" | curl -sf -X POST "$BASE_URL/unpack" \
  -H "Content-Type: application/json" -d @-)

UNSIGN_META=$(echo "$UNPACKED_SIGNED" | python3 -c 'import sys,json; m=json.load(sys.stdin)["metadata"]; print("true" if m.get("sign_from") and not m["encrypted"] else "false")' 2>/dev/null)
check "Unpack signed message shows sign_from, not encrypted" "$UNSIGN_META"

# ========================================
echo "=== 7. Anonymous Encryption (no sender) ==="
ANON=$(curl -sf -X POST "$BASE_URL/pack/encrypted" \
  -H "Content-Type: application/json" \
  -d "{
    \"message\":$MSG,
    \"to\":\"did:example:bob\",
    \"from\":null,
    \"options\":{\"forward\":false},
    \"did_docs\":[$ALICE_DID_DOC,$BOB_DID_DOC],
    \"secrets\":[]
  }")
ANON_OK=$(echo "$ANON" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("true" if d.get("packed_message") else "false")' 2>/dev/null)
check "POST /pack/encrypted (anonymous) works" "$ANON_OK"

# Unpack anonymous
ANON_MSG=$(echo "$ANON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["packed_message"])' 2>/dev/null)
ANON_UNPACK_REQ=$(python3 -c "
import json
print(json.dumps({
  'packed_message': '''$ANON_MSG'''.strip(),
  'did_docs': [json.loads('''$ALICE_DID_DOC'''), json.loads('''$BOB_DID_DOC''')],
  'secrets': [json.loads('''$BOB_SECRET_X25519''')]
}))
" 2>/dev/null)

ANON_UNPACKED=$(echo "$ANON_UNPACK_REQ" | curl -sf -X POST "$BASE_URL/unpack" \
  -H "Content-Type: application/json" -d @-)
ANON_META=$(echo "$ANON_UNPACKED" | python3 -c 'import sys,json; m=json.load(sys.stdin)["metadata"]; print("true" if m["anonymous_sender"] else "false")' 2>/dev/null)
check "Anonymous message metadata shows anonymous_sender" "$ANON_META"

# ========================================
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
