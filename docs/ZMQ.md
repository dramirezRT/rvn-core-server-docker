# ZMQ Notifications

Ravencoin Core v4.6.1 supports ZMQ (ZeroMQ) pub/sub notifications for real-time event streaming. This is useful for building block explorers, wallets, ElectrumX servers, and other downstream services that need to react to new blocks and transactions without polling the RPC.

## Quick Start

Enable all ZMQ topics with a single environment variable:

```bash
docker run -d \
  -e ZMQ=true \
  -p 28332:28332 \
  -p 28333:28333 \
  ...
```

## Supported Topics

| Topic | Port | Payload | Verified | Description |
|-------|------|---------|----------|-------------|
| `hashblock` | 28332 | 32-byte block hash | ✅ | Published when a new block is connected to the chain |
| `hashtx` | 28332 | 32-byte tx hash | ✅ | Published for each transaction added to the mempool or included in a block |
| `rawblock` | 28333 | Full serialized block | ✅ | Full raw block data (can be large) |
| `rawtx` | 28333 | Full serialized transaction | ✅ | Full raw transaction data |
| `rawmessage` | — | — | ❌ | Not functional in Ravencoin Core v4.6.1 |

### Port Layout

- **Port 28332** — `hashblock`, `hashtx` (lightweight hash-based notifications)
- **Port 28333** — `rawblock`, `rawtx` (full serialized data)

## Important Notes

- The `getzmqnotifications` RPC (available in Bitcoin Core) is **not ported** to Ravencoin Core v4.6.1. There is no RPC method to query active ZMQ endpoints at runtime.
- ZMQ is configured exclusively via `raven.conf` or command-line flags.
- The `rawmessage` topic exists in the binary but does not produce any messages in Ravencoin Core v4.6.1.

## Message Format

Each ZMQ message is a multi-part message with 3 frames:

| Frame | Content | Example |
|-------|---------|---------|
| 1 | Topic string | `hashblock` |
| 2 | Payload (binary) | 32-byte hash or serialized block/tx |
| 3 | Sequence number (4-byte little-endian uint32) | `0` (resets on daemon restart) |

### Payload Details

| Topic | Payload Size | Format |
|-------|-------------|--------|
| `hashblock` | 32 bytes | Block hash in internal byte order |
| `hashtx` | 32 bytes | Transaction hash in internal byte order |
| `rawblock` | Variable | Full serialized block (header + transactions) |
| `rawtx` | Variable | Full serialized transaction |

## Examples

### Python — Subscribe to New Blocks

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

### Python — Subscribe to All Topics

```python
import zmq
import threading

def subscribe(port, topics):
    ctx = zmq.Context()
    sock = ctx.socket(zmq.SUB)
    sock.connect(f"tcp://localhost:{port}")
    for topic in topics:
        sock.setsockopt_string(zmq.SUBSCRIBE, topic)

    while True:
        parts = sock.recv_multipart()
        topic = parts[0].decode()
        body = parts[1]
        seq = int.from_bytes(parts[2], "little")
        print(f"[{topic}] size={len(body)}B seq={seq} data={body.hex()[:64]}...")

# Hash notifications on port 28332
t1 = threading.Thread(target=subscribe, args=(28332, ["hashblock", "hashtx"]))
t1.daemon = True
t1.start()

# Raw data notifications on port 28333
t2 = threading.Thread(target=subscribe, args=(28333, ["rawblock", "rawtx"]))
t2.daemon = True
t2.start()

t1.join()
```

### Node.js — Subscribe to New Blocks

```javascript
const zmq = require("zeromq");

async function run() {
  const sock = new zmq.Subscriber();
  sock.connect("tcp://localhost:28332");
  sock.subscribe("hashblock");

  for await (const [topic, body, seq] of sock) {
    const hash = body.toString("hex");
    const sequence = seq.readUInt32LE(0);
    console.log(`New block: ${hash} (seq=${sequence})`);
  }
}

run();
```

## Verifying ZMQ

Since there is no `getzmqnotifications` RPC in Ravencoin, use these methods to verify ZMQ is working:

### 1. Check Listening Ports

```bash
docker exec rvn-node cat /proc/net/tcp \
  | awk '$4=="0A"' \
  | awk '{print $2}' \
  | cut -d: -f2 \
  | while read h; do printf "%d\n" "0x$h"; done \
  | sort -n
# Should include 28332 and 28333
```

### 2. Check ZMQ Library

```bash
docker exec rvn-node ldd /usr/local/bin/ravend | grep zmq
# Expected: libzmq.so.5 => /lib/x86_64-linux-gnu/libzmq.so.5
```

### 3. Check Binary Supports ZMQ

```bash
docker exec rvn-node ravend --help 2>&1 | grep zmq
# Should list: -zmqpubhashblock, -zmqpubhashtx, -zmqpubrawblock, -zmqpubrawtx, -zmqpubrawmessage
```

### 4. Subscribe and Wait for a Message

Use any of the code examples above, or a quick one-liner:

```bash
docker exec rvn-node python3 -c "
import zmq
ctx = zmq.Context()
s = ctx.socket(zmq.SUB)
s.connect('tcp://127.0.0.1:28332')
s.setsockopt_string(zmq.SUBSCRIBE, 'hashblock')
s.setsockopt(zmq.RCVTIMEO, 120000)
try:
    t, b, seq = s.recv_multipart()
    print(f'OK: {t.decode()} {b.hex()}')
except zmq.error.Again:
    print('Timeout (no block in 120s, but socket connected)')
"
```

## Underlying Configuration

When `ZMQ=true` is set, the entrypoint script uncomments and sets these lines in `raven.conf`:

```ini
zmqpubhashblock=tcp://0.0.0.0:28332
zmqpubhashtx=tcp://0.0.0.0:28332
zmqpubrawblock=tcp://0.0.0.0:28333
zmqpubrawtx=tcp://0.0.0.0:28333
```

These can also be passed directly as `ravend` command-line flags:

```
-zmqpubhashblock=tcp://0.0.0.0:28332
-zmqpubhashtx=tcp://0.0.0.0:28332
-zmqpubrawblock=tcp://0.0.0.0:28333
-zmqpubrawtx=tcp://0.0.0.0:28333
```
