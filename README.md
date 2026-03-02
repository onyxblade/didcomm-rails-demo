# didcomm-rails-demo

A demo project showing how to use [DIDComm v2](https://identity.foundation/didcomm-messaging/spec) messaging from a Ruby on Rails application via a Dockerized HTTP service.

## Goal

Build a Rails application that performs DIDComm v2 operations (encrypt, sign, decrypt, verify) by calling a sidecar HTTP service. This avoids the need for native Rust/C bindings in Ruby — Rails simply makes HTTP calls to the DIDComm service.

## Architecture

```
┌──────────────┐       HTTP        ┌──────────────────┐
│              │  ───────────────► │                  │
│  Rails App   │  localhost:3000   │  DIDComm HTTP    │
│              │  ◄─────────────── │  (Node + WASM)   │
└──────────────┘                   └──────────────────┘
        │
        │  HTTP                    ┌──────────────────┐
        └─────────────────────────►│ Universal        │
           localhost:8080          │ Resolver (did:web)│
                                   └────────┬─────────┘
                                            │
                                   ┌────────▼─────────┐
                                   │ driver-did-web   │
                                   └──────────────────┘
```

- **didcomm-http**: A lightweight Node.js service (~120 lines) wrapping [didcomm-rust](https://github.com/sicpa-dlab/didcomm-rust) WASM bindings. Stateless — DID Documents and secrets are passed in with each request.
- **uni-resolver-web**: [Universal Resolver](https://github.com/decentralized-identity/universal-resolver) instance configured with `did:web` only. Rails will call its REST API to resolve DIDs into DID Documents.
- **driver-did-web**: The `did:web` driver used by the Universal Resolver.
- **Rails app**: (TODO) A Rails application that demonstrates DIDComm messaging by calling the didcomm-http service.

All services are orchestrated via `docker-compose.yml`.

## Project Structure

```
.
├── docker-compose.yml       # Orchestrates all services
├── didcomm-http/            # DIDComm HTTP service (done)
│   ├── Dockerfile
│   ├── server.js            # Express server with DIDComm endpoints
│   ├── package.json
│   ├── test.sh              # Integration tests
│   └── README.md            # API documentation
└── (rails app - TODO)
```

### Resolver API

Resolve a DID Document:

```bash
curl http://localhost:8080/1.0/identifiers/did:web:did.actor:alice
```

## Quick Start

```bash
docker compose up --build
```

## Status

- [x] DIDComm HTTP service (didcomm-http)
- [x] API documentation (didcomm-http/README.md)
- [x] Integration tests (didcomm-http/test.sh)
- [x] Docker Compose setup
- [x] Universal Resolver (did:web)
- [ ] Rails application
