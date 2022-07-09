# 👋 ympd Readme 👋

ympd README

## Run container

### via command line

```shell
docker run -d \
--restart always \
--name ympd \
--device /dev/snd \
-e HOSTNAME=ympd \
-e TZ=${TIMEZONE:-America/New_York} \
-e MYMPD_SSL=false \
-v $PWD/ympd/data/mpd:/var/lib/mpd:z \
-v $PWD/ympd/data/mympd:/var/lib/mympd:z \
-v $PWD/ympd/config:/config:z \
-v $HOME/Music:/music:z \
-p 6600:600 \
-p 8082:8082 \
casjaysdev/ympd:latest
```

### via docker-compose

```yaml
version: "2"
services:
  ympd:
    image: casjaysdevdocker/ympd
    container_name: ympd
    environment:
      - TZ=America/New_York
      - HOSTNAME=ympd
    volumes:
      - $HOME/Music:/music
      - $HOME/.local/share/docker/storage/ympd/data/mpd:/var/lib/mpd \
      - $HOME/.local/share/docker/storage/ympd/data/mympd:/var/lib/mympd \
      - $HOME/.local/share/docker/storage/ympd/config:/config \
    ports:
      - 80:80
    restart: always
```

## Authors  

🤖 Casjay: [Github](https://github.com/casjay) [Docker](https://hub.docker.com/casjay) 🤖  
⛵ CasjaysDev: [Github](https://github.com/casjaysdev) [Docker](https://hub.docker.com/casjaysdev) ⛵  
