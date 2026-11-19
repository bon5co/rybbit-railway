#!/bin/bash
# Start the Rybbit client and the same-origin nginx gateway; exit if either stops.
set -euo pipefail

LISTEN_PORT="${PORT:-8080}"
CLIENT_PORT="${CLIENT_PORT:-3002}"
BACKEND_UPSTREAM="${BACKEND_UPSTREAM:-backend.railway.internal:3001}"

# Railway variables are often written as full URLs or bare hosts; nginx wants host:port.
BACKEND_UPSTREAM="${BACKEND_UPSTREAM#http://}"
BACKEND_UPSTREAM="${BACKEND_UPSTREAM#https://}"
BACKEND_UPSTREAM="${BACKEND_UPSTREAM%/}"
case "$BACKEND_UPSTREAM" in
  *:*) ;;
  *) BACKEND_UPSTREAM="${BACKEND_UPSTREAM}:3001" ;;
esac

RESOLVER="$(awk '/^nameserver/ { print $2; exit }' /etc/resolv.conf)"
[ -n "$RESOLVER" ] || RESOLVER="127.0.0.11"
case "$RESOLVER" in
  \[*\]) ;;
  *:*) RESOLVER="[${RESOLVER}]" ;;
esac

sed \
  -e "s|__LISTEN_PORT__|${LISTEN_PORT}|g" \
  -e "s|__CLIENT_PORT__|${CLIENT_PORT}|g" \
  -e "s|__BACKEND_UPSTREAM__|${BACKEND_UPSTREAM}|g" \
  -e "s|__RESOLVER__|${RESOLVER}|g" \
  /etc/nginx/railway.conf.template > /etc/nginx/http.d/rybbit.conf

echo "[rybbit-app] listen=${LISTEN_PORT} client=127.0.0.1:${CLIENT_PORT} backend=${BACKEND_UPSTREAM}"
nginx -t

cd /app
PORT="$CLIENT_PORT" HOSTNAME=127.0.0.1 node server.js &
client_pid=$!

nginx -g 'daemon off;' &
nginx_pid=$!

terminate() {
  kill "$client_pid" "$nginx_pid" 2>/dev/null || true
}
trap terminate TERM INT

wait -n "$client_pid" "$nginx_pid" || true
echo "[rybbit-app] a process exited; stopping container" >&2
terminate
wait || true
exit 1
