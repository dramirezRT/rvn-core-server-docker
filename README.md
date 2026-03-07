# rvn-core-server-docker

Dockerized Ravencoin Core full node, built from source with **ZMQ notification support**.

## Docker Hub

Pre-built images: [dramirezrt/ravencoin-core-server](https://hub.docker.com/r/dramirezrt/ravencoin-core-server)

```bash
docker pull dramirezrt/ravencoin-core-server:latest
```

### Available Tags

| Tag | Ravencoin Core | Base Image | ZMQ | Notes |
|-----|---------------|------------|-----|-------|
| `v4.6.1` | 4.6.1 | Ubuntu 22.04 | ✅ | Built from source |
| `v2.3.1` | — | Ubuntu 20.04 | ❌ | Legacy (pre-built binary) |
| `v2.3` | — | Ubuntu 20.04 | ❌ | Legacy |
| `v2.0` | — | Ubuntu 20.04 | ❌ | Legacy |
| `v1.1` | — | Ubuntu 20.04 | ❌ | Legacy |

## What It Does

1. Downloads and seeds the Ravencoin bootstrap file via BitTorrent
2. Runs the Raven Core full node (`ravend`) — built from source with ZMQ
3. Serves a simple status monitoring frontend
4. Exposes ZMQ pub/sub endpoints for real-time block and transaction notifications

## Features

- **Built from source** — not pre-compiled binaries, so ZMQ and UPnP are fully supported
- **ZMQ notifications** — real-time `hashblock` and `hashtx` events for downstream services
- **REST API** — enabled by default (`rest=1`) for block/tx data retrieval
- **Bootstrap seeding** — BitTorrent-based blockchain bootstrap for faster initial sync
- **Environment variables** — configurable ports, UPnP, ZMQ, and user agent

## Usage

### Basic

```bash
docker run -d \
  -v ~/raven-node/kingofthenorth/:/kingofthenorth \
  -v /home/kingofthenorth \
  -p 31413:31413/tcp \
  -p 31413:31413/udp \
  -p 38767:38767 \
  -p 8080:8080 \
  --name rvn-node dramirezrt/ravencoin-core-server:latest
```

### With UPnP (host networking)

```bash
docker run -d \
  -v ~/raven-node/kingofthenorth/:/kingofthenorth \
  -v /home/kingofthenorth \
  -e UPNP=true \
  --net=host \
  --name rvn-node dramirezrt/ravencoin-core-server:latest
```

### With ZMQ Enabled

```bash
docker run -d \
  -v ~/raven-node/kingofthenorth/:/kingofthenorth \
  -v /home/kingofthenorth \
  -e ZMQ_HASHBLOCK_PORT=28332 \
  -e ZMQ_HASHTX_PORT=28333 \
  -p 38767:38767 \
  -p 28332:28332 \
  -p 28333:28333 \
  -p 8080:8080 \
  --name rvn-node dramirezrt/ravencoin-core-server:latest
```

### Full Custom Configuration

```bash
docker run -d \
  -v ~/raven-node/kingofthenorth/:/kingofthenorth \
  -v /home/kingofthenorth \
  -e UPNP=true \
  -e RAVEN_PORT=8767 \
  -e TRANSMISSION_PORT=51413 \
  -e FRONTEND_PORT=8069 \
  -e ZMQ_HASHBLOCK_PORT=28332 \
  -e ZMQ_HASHTX_PORT=28333 \
  -e UACOMMENT=MyNode \
  --net=host \
  --name rvn-node dramirezrt/ravencoin-core-server:latest
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `UPNP` | `false` | Enable UPnP port forwarding (use with `--net=host`) |
| `RAVEN_PORT` | `38767` | Ravencoin P2P port (official Ravencoin mainnet port is `8767`) |
| `TRANSMISSION_PORT` | — | Custom BitTorrent port for bootstrap seeding |
| `FRONTEND_PORT` | `8080` | Status frontend port |
| `UACOMMENT` | _(empty)_ | Custom user agent comment for the node |
| `ZMQ_HASHBLOCK_PORT` | _(disabled)_ | Enable ZMQ hashblock notifications on this port |
| `ZMQ_HASHTX_PORT` | _(disabled)_ | Enable ZMQ hashtx notifications on this port |

## Exposed Ports

| Port | Protocol | Service |
|------|----------|---------|
| `38767` | TCP | Ravencoin P2P (mainnet default) |
| `31413` | TCP/UDP | BitTorrent (bootstrap seeding) |
| `8080` | TCP | Status monitoring frontend |
| `28332` | TCP | ZMQ hashblock notifications (when enabled) |
| `28333` | TCP | ZMQ hashtx notifications (when enabled) |

## Volumes

| Path | Purpose |
|------|---------|
| `/kingofthenorth/` | Blockchain data and bootstrap files (persistent) |
| `/home/kingofthenorth/` | Application home directory |

## Build From Source

```bash
# Build with default Ravencoin version (v4.6.1)
docker build -t ravencoin-core-server .

# Build with specific version
docker build --build-arg RAVENCOIN_TAG=v4.6.1 -t ravencoin-core-server:v4.6.1 .
```

## CI/CD

This repo uses GitHub Actions to automatically build and push Docker images on tag push.
Tags must be on the `main` branch and follow semver (`v*`).

The workflow:
1. Builds `ravend` from source inside Docker (multi-stage)
2. Pushes to Docker Hub as `dramirezrt/ravencoin-core-server:<tag>`
3. Tags `latest` only for the highest semver version
4. Creates a GitHub Release with upstream release notes
5. Syncs the README to Docker Hub

The `DOCKER_HUB_TOKEN` secret must be set in the repository settings.

## Architecture

```
┌─────────────────────────────────────────────────┐
│  rvn-core-server container                      │
│                                                 │
│  ┌──────────┐  ┌─────────────┐  ┌───────────┐  │
│  │  ravend   │  │ transmission│  │  node.js  │  │
│  │  (core)   │  │  (bootstrap)│  │ (frontend)│  │
│  └─────┬─────┘  └─────────────┘  └───────────┘  │
│        │                                         │
│   P2P :38767                        HTTP :8080   │
│   ZMQ :28332 (hashblock)                        │
│   ZMQ :28333 (hashtx)                           │
│   REST :38766 (API)                             │
└─────────────────────────────────────────────────┘
```

## ravend Reference

Full `ravend --help` output is available at [ravend-help.log](ravend-help.log).

## Donations

- **RVN:** RFxiRVE8L7MHVYfNP2X9eMMKUPk83uYfpZ
- **FLUX:** t1ZsWHkFRfutSMCY1KPyk35k2pkNJ2GPjPU
