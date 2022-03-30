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

## Usage
Pre-built image based from this repo's tags can be found here [https://hub.docker.com/repository/docker/dramirezrt/ravencoin-core-server](https://hub.docker.com/repository/docker/dramirezrt/ravencoin-core-server)

And can be pulled and ran with:
```
    docker run -d -p 8767:8767 dramirezrt/ravencoin-core-server:latest
```

I included the ravend help output to have it handy for any additional/special configuration for flags, available at [https://github.com/dramirezRT/rvn-core-server-docker/blob/main/ravend-help.log](https://github.com/dramirezRT/rvn-core-server-docker/blob/main/ravend-help.log)

### For donations
RVN address: RBvMDKvuvhy9MSsbs8TsSEiZ5vmqe9XDSh

FLUX address: t1ZsWHkFRfutSMCY1KPyk35k2pkNJ2GPjPU
