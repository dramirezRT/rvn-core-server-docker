FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update && apt-get -qq upgrade -y

RUN apt-get -qq update && apt-get install -qq -y \
    jq unzip tar fail2ban curl wget gawk sed vim tree \
    transmission-daemon nodejs npm && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash kingofthenorth

VOLUME [ "/home/kingofthenorth/" ]

COPY --chown=kingofthenorth:kingofthenorth ./files/rvn_init /usr/local/bin/raven_init
COPY --chown=kingofthenorth:kingofthenorth ./files/raven_status /usr/local/bin/raven_status

ENV TAG latest

# Setup raven init script
RUN chmod +x /usr/local/bin/raven_init && \
    /usr/local/bin/raven_init install_rvn
RUN chmod +x /usr/local/bin/raven_status

COPY --chown=kingofthenorth:kingofthenorth ./files/raven.conf /home/kingofthenorth/.raven/
# COPY ./files/raven.conf /root/.raven

# Setup transmission-client
RUN mkdir -p /home/kingofthenorth/.config/transmission-daemon/seeding

COPY --chown=kingofthenorth:kingofthenorth ./files/transmission.settings.json /home/kingofthenorth/.config/transmission-daemon/settings.json
COPY --chown=kingofthenorth:kingofthenorth ./files/rvn-bootstrap.md5 /home/kingofthenorth/.config/transmission-daemon/seeding/
COPY --chown=kingofthenorth:kingofthenorth ./files/rvn-bootstrap.tar.gz.torrent /home/kingofthenorth/.config/transmission-daemon/seeding/

# Setup nodejs app
COPY --chown=kingofthenorth:kingofthenorth ./rvn-node-frontend-docker /home/kingofthenorth/nodejs-app/

# RUN chown -R kingofthenorth:kingofthenorth /home/kingofthenorth/

USER kingofthenorth
WORKDIR /home/kingofthenorth

EXPOSE 8767
EXPOSE 51413/tcp
EXPOSE 51413/udp
EXPOSE 8080

ENTRYPOINT /usr/local/bin/raven_init init
