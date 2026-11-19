#!/bin/bash
# Railway-specific preparation, then hand over to the stock ClickHouse entrypoint.
set -eo pipefail

DATA_DIR="${CLICKHOUSE_DATA_DIR:-/var/lib/clickhouse}"

# Railway mounts volumes owned by uid 0 and ext4 puts a lost+found in them.
if [ -d "$DATA_DIR" ]; then
  rm -rf "$DATA_DIR/lost+found" || true
  if [ "$(id -u)" = "0" ]; then
    chown -R clickhouse:clickhouse "$DATA_DIR" || true
  fi
fi

# Size the query thread limit to THIS container: ClickHouse reads the host's core
# count, not the cgroup quota, and oversubscribes a small Railway plan.
cpu_max_file=/sys/fs/cgroup/cpu.max
cpus=""
if [ -r "$cpu_max_file" ]; then
  read -r quota period < "$cpu_max_file" || true
  if [ "$quota" != "max" ] && [ -n "$quota" ] && [ -n "$period" ] && [ "$period" -gt 0 ]; then
    cpus=$(( quota / period ))
    [ "$cpus" -lt 1 ] && cpus=1
  fi
fi
[ -z "$cpus" ] && cpus=$(nproc 2>/dev/null || echo 2)

{
  echo '<clickhouse>'
  echo "  <concurrent_threads_soft_limit_num>${cpus}</concurrent_threads_soft_limit_num>"
  echo '</clickhouse>'
} > /etc/clickhouse-server/config.d/railway-limits.xml

echo "[rybbit-clickhouse] cgroup cpus=${cpus} -> concurrent_threads_soft_limit_num=${cpus}"

exec /entrypoint.sh "$@"
