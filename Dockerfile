FROM ubuntu:20.04

RUN apt-get update && apt-get upgrade -y

RUN apt-get update && apt-get install -y \
    jq unzip tar fail2ban curl wget gawk sed vim tree && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash kingofthenorth

COPY ./files/rvn_init /usr/local/bin/raven_init
COPY ./files/raven_status /usr/local/bin/raven_status

ENV TAG latest

RUN chmod +x /usr/local/bin/raven_init &&\
    /usr/local/bin/raven_init install
RUN chmod +x /usr/local/bin/raven_status
RUN rm -f /usr/local/bin/raven_init


VOLUME [ "/home/kingofthenorth/.raven" ]
RUN chown -R kingofthenorth:kingofthenorth /home/kingofthenorth/.raven
COPY ./files/raven.conf /home/kingofthenorth/.raven
COPY ./files/raven.conf /root/.raven

USER kingofthenorth
WORKDIR /home/kingofthenorth

EXPOSE 8767

ENTRYPOINT ravend 
