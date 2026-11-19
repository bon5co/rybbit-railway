# ClickHouse for Rybbit on Railway.
#
# Upstream's docker-compose injects four config files through compose `configs:`,
# which a template cannot do, so they are baked in here. On top of that a Railway
# deploy needs what a compose volume does not: the volume is mounted root-owned and
# carries a lost+found directory that ClickHouse would treat as a database.
# upstream: ClickHouse/ClickHouse
FROM clickhouse/clickhouse-server@sha256:85c434814ac8905e5648027ce926f74ab067edd6aadbccb6c0c165cd3571ea49

COPY config/logging_rules.xml /etc/clickhouse-server/config.d/logging_rules.xml
COPY config/resource_limits.xml /etc/clickhouse-server/config.d/resource_limits.xml
COPY config/user_settings.xml /etc/clickhouse-server/users.d/user_settings.xml
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod +x /usr/local/bin/railway-entrypoint.sh

# Baked so the deploy form stays empty: a literal template variable publishes as a blank required field.
ENV CLICKHOUSE_DB=analytics \
    CLICKHOUSE_USER=default \
    CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1

EXPOSE 8123
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
