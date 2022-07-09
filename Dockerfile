FROM casjaysdevdocker/alpine:latest as build

WORKDIR /app/src

ENV \
  EMBEDDED_ASSETS="ON" \
  ENABLE_FLAC="ON" \
  ENABLE_IPV6="OFF" \
  ENABLE_LIBASAN="OFF" \
  ENABLE_SSL="ON" \
  MANPAGES="ON" \
  MYMPD_BUILDIR="build" \
  DESTDIR="/app/dist" \
  MYMPD_INSTALL_PREFIX="/usr" \
  MPD_HOST="172.17.0.1" \
  MPD_PORT="6600"

RUN apk -U upgrade && \
  apk add --no-cache \
  cmake \
  perl \
  libid3tag-dev \
  flac-dev \
  lua5.4-dev \
  alpine-sdk \
  linux-headers \
  pkgconf \
  pcre2-dev \
  jq \
  g++ \
  make \
  libmpdclient-dev \
  openssl-dev \
  git \
  abuild \
  musl-dev

RUN \
  git clone https://github.com/jcorporation/myMPD ./ && \
  bash ./build.sh installdeps && \
  bash ./build.sh releaseinstall \
  mkdir -p "$DESTDIR" 

COPY ./bin/. ${DESTDIR}/usr/local/bin/

FROM casjaysdevdocker/alpine:latest
ARG BUILD_DATE="$(date +'%Y-%m-%d %H:%M')" 

LABEL \
  org.label-schema.name="ympd" \
  org.label-schema.description="Web interface to mpd" \
  org.label-schema.url="https://hub.docker.com/r/casjaysdevdocker/ympd" \
  org.label-schema.vcs-url="https://github.com/casjaysdevdocker/ympd" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.version=$BUILD_DATE \
  org.label-schema.vcs-ref=$BUILD_DATE \
  org.label-schema.license="WTFPL" \
  org.label-schema.vcs-type="Git" \
  org.label-schema.schema-version="1.0" \
  org.label-schema.vendor="CasjaysDev" \
  maintainer="CasjaysDev <docker-admin@casjaysdev.com>" 

RUN apk -U upgrade && \
  apk add --no-cache \
  libmpdclient \
  openssl \
  libid3tag \
  flac \
  lua5.4 \
  pcre2 \
  mpc \
  mpd \
  pulseaudio-utils

RUN addgroup -S mympd 2>/dev/null && \
  adduser -S -D -H -h /var/lib/mympd -s /sbin/nologin \
  -G mympd -g myMPD mympd 2>/dev/null

EXPOSE 8082 6600
ENV HOSTNAME="ympd" 

COPY --from=build /app/dist/. /
COPY ./config/mpd.conf /etc/mpd.conf
COPY ./config/mympd/. /var/lib/mympd/config/
COPY ./config/pulse-client.conf /etc/pulse/client.conf

VOLUME [ "/config", "/var/lib/mpd", "/var/lib/mympd", "/music", "/playlists" ]
HEALTHCHECK CMD ["/usr/local/bin/entrypoint-ympd.sh", "healthcheck"]
ENTRYPOINT ["/usr/local/bin/entrypoint-ympd.sh"] 
