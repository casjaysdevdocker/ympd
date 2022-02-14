#!/usr/bin/env bash

DOCKER_PORT="8082"
DOCKER_HOST="$(ip route | awk '/default/ { print $3 }')"
export TZ="${TZ:-America/New_York}"
export HOSTNAME="${HOSTNAME:-casjaysdev-ympd}"

[ -n "${TZ}" ] && echo "${TZ}" >/etc/timezone
[ -n "${HOSTNAME}" ] && echo "${HOSTNAME}" >/etc/hostname
[ -n "${HOSTNAME}" ] && echo "127.0.0.1 $HOSTNAME localhost" >/etc/hosts
[ -f "/usr/share/zoneinfo/${TZ}" ] && ln -sf "/usr/share/zoneinfo/${TZ}" "/etc/localtime"
[ -d "/config/mympd" ] || mkdir -p "/config/mympd"

if [ ! -f "/config/mympd/.env" ]; then
  cat <<EOF >"/config/mympd/.env"
# See https://jcorporation.github.io/myMPD/configuration/ for more information
export MPD_HOST=$DOCKER_HOST
export MPD_PORT=6600
export MYMPD_HTTP_HOST="${MYMPD_HTTP_HOST:-0.0.0.0}"
export MYMPD_HTTP_PORT="${MYMPD_HTTP_PORT:-$DOCKER_PORT}"
export MYMPD_LOGLEVEL="${MYMPD_LOGLEVEL:-5}"
export MYMPD_SSL="${MYMPD_SSL:-false}"
export MYMPD_SSL_PORT="${MYMPD_SSL_PORT:-$DOCKER_PORT}"
export MYMPD_SSL_KEY="${MYMPD_SSL_KEY:-/config/certs/mympd.key}"
export MYMPD_SSL_CERT="${MYMPD_SSL_CERT:-/config/certs/mympd.crt}"
#export MYMPD_ACL="${MYMPD_ACL:-}"
#export MYMPD_SSL_SAN="${MYMPD_SSL_SAN:-}"
#export MYMPD_LUALIBS="${MYMPD_LUALIBS:-}"
#export MYMPD_SCRIPTACL="${MYMPD_SCRIPTACL:-}"
#export MYMPD_CUSTOM_CERT="${MYMPD_CUSTOM_CERT:-}"

EOF
fi

[ -f "/config/mympd/.env" ] && . "/config/mympd/.env"
[ -f "/config/mympd/ssl" ] || printf '%s' "$MYMPD_SSL" >"/config/mympd/ssl"
[ -f "/config/mympd/http_host" ] || printf '%s' "$MYMPD_HTTP_HOST" >"/config/mympd/http_host"
[ -f "/config/mympd/http_port" ] || printf '%s' "$MYMPD_HTTP_PORT" >"/config/mympd/http_port"

[ -f "/config/pulse-client.conf" ] && cp -Rf "/config/pulse-client.conf" "/etc/pulse/client.conf" ||
  cp -Rf "/etc/pulse/client.conf" "/config/pulse-client.conf"
[ -f "/config/mpd.conf" ] && cp -Rf "/config/mpd.conf" "/etc/mpd.conf" ||
  cp -Rf "/etc/mpd.conf" "/config/mpd.conf"
[ -d "/config/mympd" ] && cp -Rf "/config/mympd/." "/var/lib/mympd/config/" ||
  cp -Rf "/var/lib/mympd/config/." "/config/mympd/"

export MYMPD_USER="--user ${MYMPD_USER:-mympd}"
export MYMPD_DIR="--workdir ${MYMPD_DIR:-/var/lib/mympd}"
export MYMPD_CACHE="--cache ${MYMPD_CACHE:-/var/cache/mympd}"

case "$1" in
healthcheck)
  shift 1
  if curl -q -LSs --fail "localhost:$DOCKER_PORT"; then
    echo '{"status": "ok" }'
    exit 0
  else
    echo '{"status": "fail" }'
    exit 1
  fi
  ;;

bash | sh | shell)
  shift 1
  exec bash -l "$@"
  ;;

*)
  echo "Setting ympd options to: ${CMDOPTS:-none}"
  if [[ $# = 0 ]]; then
    echo "listening on http://$DOCKER_HOST:$DOCKER_PORT"
    pacat -vvvv /dev/urandom
    mpd --no-daemon /etc/mpd.conf
    mympd $MYMPD_USER $MYMPD_DIR $MYMPD_CACHE $CMDOPTS
  else
    CMDOPTS="$*"
    mympd $MYMPD_USER $MYMPD_DIR $MYMPD_CACHE $CMDOPTS
    pacat -vvvv /dev/urandom
    mpd --no-daemon /etc/mpd.conf
  fi
  ;;
esac
