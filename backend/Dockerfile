# Rybbit backend with a first-boot admin and signup closed behind it.
#
# Upstream makes the first account to sign up the instance admin and exposes no
# environment variable to create it, so a public deploy would hand the instance
# to whoever reaches the sign-up form first. The entrypoint creates the admin
# from ADMIN_EMAIL / ADMIN_PASSWORD, then starts the app with DISABLE_SIGNUP=true.
# upstream: rybbit-io/rybbit
FROM ghcr.io/rybbit-io/rybbit-backend@sha256:2e87bf8be399da2cb5dede1c6edc746abd59472f89e88dc36cc28656875f24a9

COPY railway-entrypoint.sh /railway-entrypoint.sh
RUN chmod +x /railway-entrypoint.sh

# Baked so the deploy form stays empty: a literal template variable publishes as a blank required field.
ENV POSTGRES_USER=postgres \
    POSTGRES_DB=postgres \
    POSTGRES_PORT=5432 \
    REDIS_PORT=6379 \
    CLICKHOUSE_DB=analytics \
    DISABLE_TELEMETRY=true \
    CLUSTER_WORKERS=2

EXPOSE 3001
ENTRYPOINT ["/railway-entrypoint.sh"]
CMD ["node", "dist/cluster.js"]
