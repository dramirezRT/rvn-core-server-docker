FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

ARG RAVENCOIN_TAG=v4.6.1

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential libtool autotools-dev automake pkg-config \
    libssl-dev libevent-dev bsdmainutils python3 \
    libboost-system-dev libboost-filesystem-dev libboost-chrono-dev \
    libboost-program-options-dev libboost-test-dev libboost-thread-dev \
    libzmq3-dev libminiupnpc-dev \
    git curl && \
    rm -rf /var/lib/apt/lists/*

# Clone and build ravend from source with ZMQ support
RUN git clone --branch ${RAVENCOIN_TAG} --depth 1 \
    https://github.com/RavenProject/Ravencoin.git /tmp/ravencoin

WORKDIR /tmp/ravencoin

# Install Berkeley DB 4.8 (inline — upstream install_db4.sh has stale config.guess hashes)
ENV BDB_VERSION=db-4.8.30.NC
ENV BDB_PREFIX=/opt/db4/db4
RUN mkdir -p /opt/db4 && cd /opt/db4 && \
    curl --insecure --retry 5 -o ${BDB_VERSION}.tar.gz \
      "https://download.oracle.com/berkeley-db/${BDB_VERSION}.tar.gz" && \
    echo "12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef  ${BDB_VERSION}.tar.gz" | sha256sum -c && \
    tar -xzf ${BDB_VERSION}.tar.gz && \
    cd ${BDB_VERSION} && \
    # C++11 compatibility patch
    sed -i 's/atomic_init(/atomic_init_db(/g' dbinc/atomic.h mp/mp_fget.c mp/mp_mvcc.c mp/mp_region.c mutex/mut_method.c mutex/mut_tas.c && \
    sed -i 's/__atomic_compare_exchange(/__atomic_compare_exchange_db(/g' dbinc/atomic.h && \
    sed -i 's/static inline int __atomic_compare_exchange$/static inline int __atomic_compare_exchange_db/' dbinc/atomic.h && \
    # Replace stale config.guess/config.sub with system copies
    cp /usr/share/misc/config.guess dist/config.guess && \
    cp /usr/share/misc/config.sub dist/config.sub && \
    cd build_unix && \
    ../dist/configure --enable-cxx --disable-shared --disable-replication --with-pic --prefix="${BDB_PREFIX}" && \
    make -j$(nproc) && make install && \
    cd / && rm -rf /opt/db4/${BDB_VERSION} /opt/db4/${BDB_VERSION}.tar.gz

# Build ravend and raven-cli (no GUI, no wallet, with ZMQ + UPnP)
RUN ./autogen.sh && \
    ./configure \
      --disable-tests \
      --disable-bench \
      --disable-gui-tests \
      --without-gui \
      --with-zmq \
      --with-miniupnpc \
      --disable-wallet \
      LDFLAGS="-L${BDB_PREFIX}/lib/" \
      CPPFLAGS="-I${BDB_PREFIX}/include/" && \
    make -j$(nproc) && \
    strip src/ravend src/raven-cli

# ---------- runtime ----------
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    jq curl wget gawk sed vim tree \
    libzmq5 libevent-2.1-7 libevent-pthreads-2.1-7 libminiupnpc17 \
    libboost-system1.74.0 libboost-filesystem1.74.0 \
    libboost-chrono1.74.0 libboost-program-options1.74.0 \
    libboost-thread1.74.0 \
    transmission-daemon nodejs npm && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash kingofthenorth

# Copy built binaries from builder
COPY --from=builder /tmp/ravencoin/src/ravend /usr/local/bin/ravend
COPY --from=builder /tmp/ravencoin/src/raven-cli /usr/local/bin/raven-cli

VOLUME [ "/home/kingofthenorth/" ]
VOLUME [ "/kingofthenorth/" ]

COPY ./files/rvn_init /usr/local/bin/raven_init
COPY ./files/raven_status /usr/local/bin/raven_status
COPY ./files/entrypoint /usr/local/bin/entrypoint

RUN chmod +x /usr/local/bin/raven_init && \
    chmod +x /usr/local/bin/raven_status && \
    chmod +x /usr/local/bin/entrypoint

COPY --chown=kingofthenorth:kingofthenorth ./files/raven.conf /home/kingofthenorth/.raven/

# Setup transmission-client
RUN mkdir -p /home/kingofthenorth/.config/transmission-daemon/seeding

COPY --chown=kingofthenorth:kingofthenorth ./files/transmission.settings.json /home/kingofthenorth/.config/transmission-daemon/settings.json
COPY --chown=kingofthenorth:kingofthenorth ./files/rvn-bootstrap.md5 /home/kingofthenorth/.config/transmission-daemon/seeding/
COPY --chown=kingofthenorth:kingofthenorth ./files/rvn-bootstrap*.tar.gz.torrent /home/kingofthenorth/.config/transmission-daemon/seeding/

# Setup nodejs app
COPY --chown=kingofthenorth:kingofthenorth ./rvn-node-frontend-docker /home/kingofthenorth/nodejs-app/

WORKDIR /home/kingofthenorth

# P2P
EXPOSE 38767
# Transmission (bootstrap seeding)
EXPOSE 31413/tcp
EXPOSE 31413/udp
# Frontend
EXPOSE 8080
# ZMQ notifications
EXPOSE 28332
EXPOSE 28333

ENTRYPOINT ["/usr/local/bin/entrypoint", "/usr/local/bin/raven_init init"]
