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
  -e ZMQ=true \
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
  -e ZMQ=true \
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
| `ZMQ` | `false` | Enable all ZMQ notifications (`hashblock`/`hashtx` on port 28332, `rawblock`/`rawtx` on port 28333) |

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

## ZMQ Notifications

Ravencoin Core v4.6.1 supports ZMQ (ZeroMQ) pub/sub notifications for real-time event streaming. This is useful for building block explorers, wallets, ElectrumX servers, and other downstream services that need to react to new blocks and transactions without polling the RPC.

### Supported Topics

| Topic | Port (default) | Payload | Verified | Description |
|-------|---------------|---------|----------|-------------|
| `hashblock` | 28332 | 32-byte block hash | ✅ | Published when a new block is connected to the chain |
| `hashtx` | 28333 | 32-byte tx hash | ✅ | Published for each transaction added to the mempool or included in a block |
| `rawblock` | 28332 | Full serialized block | ✅ | Full raw block data (can be large) |
| `rawtx` | 28333 | Full serialized transaction | ✅ | Full raw transaction data |
| `rawmessage` | — | — | ❌ | Not functional in Ravencoin Core v4.6.1 |

> **Note:** The `getzmqnotifications` RPC (available in Bitcoin Core) is **not ported** to Ravencoin Core v4.6.1. ZMQ is configured exclusively via `raven.conf` or command-line flags. There is no RPC method to query active ZMQ endpoints at runtime.

### Enabling ZMQ

ZMQ is **disabled by default**. Enable all topics with a single flag:

```bash
docker run -d \
  -e ZMQ=true \
  -p 28332:28332 \
  -p 28333:28333 \
  ...
```

This enables all 4 functional topics on fixed ports:
- **Port 28332** — `hashblock`, `hashtx` (hash-based notifications)
- **Port 28333** — `rawblock`, `rawtx` (full serialized data)

### ZMQ Message Format

Each ZMQ message is a multi-part message with 3 frames:

| Frame | Content | Example |
|-------|---------|---------|
| 1 | Topic string | `hashblock` |
| 2 | Payload (binary) | 32-byte hash or serialized block/tx |
| 3 | Sequence number (4-byte LE uint32) | `0` (resets on restart) |

### Example: Python ZMQ Subscriber

```python
import zmq

ctx = zmq.Context()
sock = ctx.socket(zmq.SUB)
sock.connect("tcp://localhost:28332")
sock.setsockopt_string(zmq.SUBSCRIBE, "hashblock")

while True:
    topic, body, seq = sock.recv_multipart()
    block_hash = body.hex()
    sequence = int.from_bytes(seq, "little")
    print(f"New block: {block_hash} (seq={sequence})")
```

### Verifying ZMQ

Since there is no `getzmqnotifications` RPC, verify ZMQ is working by:

1. **Check listening ports** inside the container:
   ```bash
   docker exec rvn-node cat /proc/net/tcp | awk '$4=="0A"' | awk '{print $2}' | cut -d: -f2 | while read h; do printf "%d\n" "0x$h"; done | sort -n
   # Should show 28332 and/or 28333
   ```

2. **Subscribe and wait for a message** (see Python example above)

3. **Check the binary has ZMQ support:**
   ```bash
   docker exec rvn-node ldd /usr/local/bin/ravend | grep zmq
   # Should show: libzmq.so.5 => /lib/x86_64-linux-gnu/libzmq.so.5
   ```

## ravend Reference

Full `ravend --help` output is available at [ravend-help.log](ravend-help.log).

## Donations

- **RVN:** RFxiRVE8L7MHVYfNP2X9eMMKUPk83uYfpZ
- **FLUX:** t1ZsWHkFRfutSMCY1KPyk35k2pkNJ2GPjPU
