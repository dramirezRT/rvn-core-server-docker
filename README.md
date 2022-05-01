# rvn-core-server-docker

## Description
Images are built from the Official Ravencoin Core Server Repository for the Ravencoin Project https://github.com/RavenProject/Ravencoin/releases

## Build
Using docker engine you can build your own image with:
```
    docker build -t <your-docker-user>/<your-repo-name>:<tag>
```
or

```
    docker build -t <repo-name>:<tag>
```
## What it does?
The built container will be in charge of:
1. Downloading and sharing the Ravencoin bootstrap file.
2. Install and setup the Raven Core node
3. Run a simple website to monitor the node status

## Usage
Pre-built image based from this repo's tags can be found here [https://hub.docker.com/repository/docker/dramirezrt/ravencoin-core-server](https://hub.docker.com/repository/docker/dramirezrt/ravencoin-core-server)

## Normal usage
```
docker run -d \
            -v ~/raven-node/kingofthenorth/:/kingofthenorth \
            -v /home/kingofthenorth \
            -p 31413:31413/tcp \
            -p 31413:31413/udp \
            -p 38767:38767 \
            -p 8080:8080 \
            --name rvn-node dramirezrt/ravencoin-core-server:latest
```

## UPNP enabled
```
docker run -d \
            -v ~/raven-node/kingofthenorth/:/kingofthenorth \
            -v /home/kingofthenorth \
            -e UPNP=true \
            --net=host \
            --name rvn-node dramirezrt/ravencoin-core-server:latest
```

## Custom port setting
```
docker run -d \
            -v ~/raven-node/kingofthenorth/:/kingofthenorth \
            -v /home/kingofthenorth \
            -e UPNP=true \
            -e RAVEN_PORT=8767 \
            -e TRANSMISSION_PORT=51413 \
            -e FRONTEND_PORT=8069 \
            --net=host \
            --name rvn-node dramirezrt/ravencoin-core-server:latest
```

I included the ravend help output to have it handy for any additional/special configuration for flags, available at [https://github.com/dramirezRT/rvn-core-server-docker/blob/main/ravend-help.log](https://github.com/dramirezRT/rvn-core-server-docker/blob/main/ravend-help.log)


### For donations
RVN address: RFxiRVE8L7MHVYfNP2X9eMMKUPk83uYfpZ

FLUX address: t1ZsWHkFRfutSMCY1KPyk35k2pkNJ2GPjPU
