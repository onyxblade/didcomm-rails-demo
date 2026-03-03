# didcomm-rails-demo

A demo project showing how to use [DIDComm v2](https://identity.foundation/didcomm-messaging/spec) messaging from a Ruby on Rails application via a Dockerized HTTP service.

## Goal

Build a Rails application that performs DIDComm v2 operations (encrypt, sign, decrypt, verify) by calling a sidecar HTTP service. This avoids the need for native Rust/C bindings in Ruby — Rails simply makes HTTP calls to the DIDComm service.

## Architecture

```
Browser ──► Rails App (port 3001)
                ├── calls didcomm-http (internal, port 3000) for pack/unpack + DID resolution
                └── serves /.well-known/did.json for own DID
```

- **web**: A Rails 8.1 application with password-based auth (via `ADMIN_PASSWORD` env var), message sending/receiving, and a DIDComm inbox endpoint. Generates Ed25519/X25519 key pairs on first request and serves its own `did:web` DID Document.
- **[didcomm-http](https://github.com/onyxblade/didcomm-http)**: A TypeScript/Fastify service wrapping [didcomm-rust](https://github.com/sicpa-dlab/didcomm-rust) WASM bindings with built-in DID resolution (did:web + did:webvh). Stateless — DID Documents and secrets are passed in with each request. Provides OpenAPI documentation at `/documentation`.

## Quick Start

You only need two files to run the service: `docker-compose.yml` and `.env`.

1. Create a `.env` file:

```
RAILS_ENV=production
DOMAIN=example.com
HOST_PORT=3001
SECRET_KEY_BASE=change-me-to-a-random-secret
ADMIN_PASSWORD=change-me
```

2. Create a `docker-compose.yml`:

```yaml
services:
  web:
    image: onyxblade/didcomm-rails-demo-web:latest
    ports:
      - "${HOST_PORT}:3000"
    env_file: .env
    environment:
      - DIDCOMM_SERVICE_URL=http://didcomm:3000
    volumes:
      - ./storage:/app/storage
    depends_on:
      - didcomm

  didcomm:
    image: onyxblade/didcomm-http:latest
```

3. Start the services:

```bash
docker compose up
```

`DOMAIN` must be a publicly reachable domain (not `localhost`) because `did:web` resolution requires the DID Document to be fetchable over HTTPS by external resolvers.

The SQLite database is persisted to `./storage/` via a Docker volume mount.

Then visit:

- `https://example.com/.well-known/did.json` — View your DID Document (auto-generated on first request)
- `https://example.com/login` — Log in with your `ADMIN_PASSWORD` to send and view messages

## Key Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /login` | Log in with `ADMIN_PASSWORD` |
| `GET /messages` | Message list (requires login) |
| `GET /messages/new` | Send a DIDComm message (requires login) |
| `POST /didcomm` | Receive DIDComm messages (open API endpoint) |
| `GET /.well-known/did.json` | Serve this node's DID Document |
| `GET /` | Landing page |

## Development

```bash
cp .env.example .env         # Set DOMAIN, SECRET_KEY_BASE, and ADMIN_PASSWORD
docker compose up --build
```

### Project Structure

```
.
├── docker-compose.yml       # Orchestrates all services
├── .env.example             # Environment config template
├── build.sh                 # Build and push Docker image
├── web/                     # Rails application
│   ├── Dockerfile
│   ├── app/
│   │   ├── models/          # Identity, Message
│   │   ├── controllers/     # Sessions, Messages, Inbox, Did, Public
│   │   ├── services/        # DidcommService (pack/unpack + DID resolution)
│   │   └── views/           # HTML views
│   └── test/                # Model and controller tests
└── didcomm-http/            # DIDComm HTTP service (git submodule)
```
