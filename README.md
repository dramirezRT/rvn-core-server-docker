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
| `v2.4` | 4.6.1 | Ubuntu 22.04 | ✅ | Built from source |
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
  -v ~/raven-node/kingofthenorth:/kingofthenorth \
  -v ~/raven-node/home:/home/kingofthenorth \
  -p 31413:31413/tcp \
  -p 31413:31413/udp \
  -p 38767:38767 \
  -p 8080:8080 \
  --name rvn-node dramirezrt/ravencoin-core-server:latest
```

### With UPnP (host networking)

```bash
docker run -d \
  -v ~/raven-node/kingofthenorth:/kingofthenorth \
  -v ~/raven-node/home:/home/kingofthenorth \
  -e UPNP=true \
  --net=host \
  --name rvn-node dramirezrt/ravencoin-core-server:latest
```

### With ZMQ Enabled

```bash
docker run -d \
  -v ~/raven-node/kingofthenorth:/kingofthenorth \
  -v ~/raven-node/home:/home/kingofthenorth \
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
  -v ~/raven-node/kingofthenorth:/kingofthenorth \
  -v ~/raven-node/home:/home/kingofthenorth \
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
| `/home/kingofthenorth/` | Node home directory — config, transmission settings, logs |

### Persisting Configuration Across Rebuilds

`raven.conf` and other node settings live in `/home/kingofthenorth/` inside the container.  
By default this directory is ephemeral — it resets on every container rebuild/recreate.

To persist it, mount it as either a **host path** or a **named volume**:

**Option A — Host path** (recommended; config files are directly accessible on the host):
```bash
docker run -d \
  -v ~/raven-node/kingofthenorth:/kingofthenorth \
  -v /path/on/host/home:/home/kingofthenorth \
  --name rvn-node dramirezrt/ravencoin-core-server:latest
```
> On first run the container will populate `/path/on/host/home` from the image. Edit `raven.conf` there directly.

**Option B — Named volume** (managed by Docker; survives image updates without a host path):
```bash
docker volume create rvn-node-home

docker run -d \
  -v ~/raven-node/kingofthenorth:/kingofthenorth \
  -v rvn-node-home:/home/kingofthenorth \
  --name rvn-node dramirezrt/ravencoin-core-server:latest
```
> Inspect or edit files with: `docker run --rm -v rvn-node-home:/data alpine sh`

Without either option, any changes to `raven.conf` (custom RPC credentials, ZMQ endpoints, port overrides, etc.) will be lost when the container is removed or the image is rebuilt.

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

ZMQ is **disabled by default**. Enable all topics with a single flag:

```bash
docker run -d \
  -e ZMQ=true \
  -p 28332:28332 \
  -p 28333:28333 \
  ...
```

| Topic | Port | Verified | Description |
|-------|------|----------|-------------|
| `hashblock` | 28332 | ✅ | New block hash |
| `hashtx` | 28332 | ✅ | New transaction hash |
| `rawblock` | 28333 | ✅ | Full serialized block |
| `rawtx` | 28333 | ✅ | Full serialized transaction |

> **Note:** `getzmqnotifications` RPC is not available in Ravencoin Core v4.6.1.

📖 **Full documentation:** [docs/ZMQ.md](docs/ZMQ.md) — message format, code examples (Python & Node.js), verification steps, and configuration details.

## Blockchain Snapshots (Bootstrap)

Bootstrap snapshots allow a fresh node to skip years of chain download and sync in hours instead of weeks.

On first start the container uses BitTorrent (transmission) to download the bootstrap archive, verify its integrity, and extract it before launching `ravend`.

### Available Snapshots

| File | Date | Compressed Size | Uncompressed | Chain Coverage | Torrent |
|------|------|----------------|--------------|----------------|---------|
| `rvn-bootstrap-08232022.tar.gz` | Aug 23 2022 | ~22 GB | ~30 GB | Genesis → Aug 2022 | `rvn-bootstrap-08232022.tar.gz.torrent` |
| `rvn-bootstrap-03142026.tar.gz` | Mar 14 2026 | ~32 GB | ~45 GB | Genesis → Mar 2026 | `rvn-bootstrap-03142026.tar.gz.torrent` |

Both snapshots ship with their checksums in `rvn-bootstrap.sha512` (SHA512) and `rvn-bootstrap.md5` (MD5, legacy 2022 snapshot only). On first start the container automatically picks the latest snapshot available in `rvn-bootstrap.sha512`.

### Integrity Verification

All snapshots are verified before extraction. The node image ships with:
- `rvn-bootstrap.sha512` — SHA512 checksums (used for all new snapshots)
- `rvn-bootstrap.md5` — MD5 legacy checksum (used as fallback for the 2022 snapshot)

If both files are present, SHA512 takes precedence.

### Creating a New Snapshot

The snapshot tool ships **inside the container** — no host dependencies needed:

```bash
docker exec rvn-node create_snapshot
```

The script:
1. Sets a maintenance lock so ravend does not restart mid-backup
2. Stops `ravend` gracefully via `raven-cli stop`
3. Archives `assets/`, `blocks/`, `chainstate/` with live `pv` progress
4. Generates a SHA512 checksum and appends it to `rvn-bootstrap.sha512`
5. Creates a `.torrent` file (2 MiB piece size, DHT, no tracker required)
6. Removes the maintenance lock — `ravend` restarts automatically

After running, follow the printed next-steps to commit the new `.torrent` and updated `rvn-bootstrap.sha512` to the repo and open a PR.

## ravend Reference

Full `ravend --help` output is available at [ravend-help.log](ravend-help.log).

## Donations

- **RVN:** RFxiRVE8L7MHVYfNP2X9eMMKUPk83uYfpZ
- **FLUX:** t1ZsWHkFRfutSMCY1KPyk35k2pkNJ2GPjPU

## Related Projects

- [RVN-Electrumx-docker](https://github.com/dramirezRT/RVN-Electrumx-docker) — ElectrumX server that connects to this node as its ravend backend
- [rvn-node-frontend-docker](https://github.com/dramirezRT/rvn-node-frontend-docker) — Real-time dashboard powered by this node's ZMQ and RPC endpoints
