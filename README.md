# didcomm-rails-demo

A demo project showing how to use [DIDComm v2](https://identity.foundation/didcomm-messaging/spec) messaging from a Ruby on Rails application via a Dockerized HTTP service.

## Goal

Build a Rails application that performs DIDComm v2 operations (encrypt, sign, decrypt, verify) by calling a sidecar HTTP service. This avoids the need for native Rust/C bindings in Ruby — Rails simply makes HTTP calls to the DIDComm service.

## Architecture

```
Browser ──► Rails App (port 3001)
                ├── calls didcomm-http (internal, port 3000) for pack/unpack
                ├── calls uni-resolver-web (internal, port 8080) for DID resolution
                └── serves /.well-known/did.json for own DID
```

- **web**: A Rails 8.1 application with admin auth, message sending/receiving, a DIDComm inbox endpoint, and a public message feed. Generates Ed25519/X25519 key pairs and serves its own `did:web` DID Document.
- **didcomm-http**: A lightweight Node.js service wrapping [didcomm-rust](https://github.com/sicpa-dlab/didcomm-rust) WASM bindings. Stateless — DID Documents and secrets are passed in with each request.
- **uni-resolver-web**: [Universal Resolver](https://github.com/decentralized-identity/universal-resolver) instance for resolving DIDs into DID Documents.
- **driver-did-uport**: The [uPort DID driver](https://github.com/uport-project/uport-did-driver) handling `did:web`, `did:ethr`, and `did:peer` resolution.

All services are orchestrated via `docker-compose.yml`.

## Project Structure

```
.
├── docker-compose.yml       # Orchestrates all services
├── .env.example             # Environment config template
├── web/                     # Rails application
│   ├── Dockerfile
│   ├── app/
│   │   ├── models/          # Identity, Admin, Message
│   │   ├── controllers/     # Setup, Sessions, Messages, Inbox, Did, Public
│   │   ├── services/        # DidcommService, DidResolverService
│   │   └── views/           # HTML views
│   └── test/                # Model and controller tests
└── didcomm-http/            # DIDComm HTTP service
    ├── Dockerfile
    ├── server.js             # Express server with DIDComm endpoints
    ├── package.json
    ├── test.sh               # Integration tests
    └── README.md             # API documentation
```

## Quick Start

```bash
cp .env.example .env         # Set DOMAIN to a real domain and generate a SECRET_KEY_BASE
docker compose up --build
```

`DOMAIN` must be a publicly reachable domain (not `localhost`) because `did:web` resolution requires the DID Document to be fetchable over HTTPS by external resolvers.

Then visit:

- `https://example.com/setup` — Create admin account and generate DID
- `https://example.com/.well-known/did.json` — View your DID Document
- `https://example.com/login` — Log in to send messages
- `https://example.com/` — Public message feed

The SQLite database is persisted to `web/storage/` via a Docker volume mount.

## Key Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /setup` | First-run setup (create admin + generate DID) |
| `GET /login` | Admin login |
| `GET /messages` | Message list (requires login) |
| `GET /messages/new` | Send a DIDComm message (requires login) |
| `POST /didcomm` | Receive DIDComm messages (open API endpoint) |
| `GET /.well-known/did.json` | Serve this node's DID Document |
| `GET /` | Public message feed |

## Status

- [x] DIDComm HTTP service (didcomm-http)
- [x] API documentation (didcomm-http/README.md)
- [x] Integration tests (didcomm-http/test.sh)
- [x] Docker Compose setup
- [x] Universal Resolver (did:web via uPort driver)
- [x] Rails application
- [x] Tests (32 tests, 116 assertions)
