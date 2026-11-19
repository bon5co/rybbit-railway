#!/bin/sh
# Wait for the databases, migrate, create the first admin from ADMIN_EMAIL /
# ADMIN_PASSWORD when the instance has no user yet, then start the app with
# sign-up closed.
set -eu

PGHOST="${POSTGRES_HOST:-postgres}"
PGPORT="${POSTGRES_PORT:-5432}"
export PGPASSWORD="${POSTGRES_PASSWORD:-}"

echo "[rybbit-backend] waiting for PostgreSQL at ${PGHOST}:${PGPORT}"
until pg_isready -h "$PGHOST" -p "$PGPORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -q; do
  sleep 1
done

CH_PING="${CLICKHOUSE_HOST%/}/ping"
echo "[rybbit-backend] waiting for ClickHouse at ${CH_PING}"
attempt=0
until wget -q -T 5 -O /dev/null "$CH_PING" 2>/dev/null; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 120 ]; then
    echo "[rybbit-backend] ClickHouse unreachable at ${CH_PING}" >&2
    exit 1
  fi
  sleep 2
done

echo "[rybbit-backend] running database migrations"
npm run db:migrate

user_count() {
  psql -h "$PGHOST" -p "$PGPORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc 'SELECT count(*) FROM "user"'
}

if [ "$(user_count)" = "0" ]; then
  if [ -z "${ADMIN_EMAIL:-}" ] || [ -z "${ADMIN_PASSWORD:-}" ]; then
    echo "[rybbit-backend] ADMIN_EMAIL and ADMIN_PASSWORD are required to create the first admin" >&2
    exit 1
  fi
  echo "[rybbit-backend] no user yet: creating admin ${ADMIN_EMAIL}"
  # Sign-up has to be open for this one call and the app is not yet routable
  # through the gateway, which also refuses /api/auth/sign-up at all times.
  DISABLE_SIGNUP=false node dist/index.js >/tmp/bootstrap.log 2>&1 &
  boot_pid=$!
  attempt=0
  until wget -q -T 3 -O /dev/null "http://127.0.0.1:3001/api/health" 2>/dev/null; do
    attempt=$((attempt + 1))
    if [ "$attempt" -ge 120 ] || ! kill -0 "$boot_pid" 2>/dev/null; then
      echo "[rybbit-backend] bootstrap server did not come up:" >&2
      tail -n 30 /tmp/bootstrap.log >&2
      exit 1
    fi
    sleep 1
  done
  payload="$(node -e 'process.stdout.write(JSON.stringify({email:process.env.ADMIN_EMAIL,password:process.env.ADMIN_PASSWORD,name:"Admin"}))')"
  origin="${BASE_URL:-http://127.0.0.1:3001}"
  code="$(node -e '
    fetch("http://127.0.0.1:3001/api/auth/sign-up/email", {
      method: "POST",
      headers: { "content-type": "application/json", origin: process.argv[2] },
      body: process.argv[1],
    }).then(async r => { console.error(await r.text()); process.stdout.write(String(r.status)); });
  ' "$payload" "$origin")"
  kill "$boot_pid" 2>/dev/null || true
  wait "$boot_pid" 2>/dev/null || true
  if [ "$code" != "200" ] || [ "$(user_count)" != "1" ]; then
    echo "[rybbit-backend] admin sign-up returned HTTP ${code}, users=$(user_count)" >&2
    tail -n 30 /tmp/bootstrap.log >&2
    exit 1
  fi
  echo "[rybbit-backend] admin created"
else
  echo "[rybbit-backend] instance already has users, skipping admin bootstrap"
fi

export DISABLE_SIGNUP=true
echo "[rybbit-backend] starting: $*"
exec "$@"
