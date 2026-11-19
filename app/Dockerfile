# Rybbit web UI + same-origin gateway in one container.
#
# The published client image calls the API on its own origin, so something must
# serve the UI and /api under one domain. Upstream runs Caddy as a separate
# service for that; here nginx runs beside the client it fronts, which removes
# a whole always-on service and keeps the backend off the public internet.
# upstream: rybbit-io/rybbit
FROM ghcr.io/rybbit-io/rybbit-client@sha256:39947e9e4da4248de27f78e2fa691eb86654945dff7b74c1d732b78f13273fb3

USER root

# bash for `wait -n`: if either the client or nginx dies the container must exit
# so Railway restarts it instead of staying "healthy" while serving nothing.
RUN apk add --no-cache nginx bash \
    && mkdir -p /run/nginx /var/lib/nginx/tmp \
    && rm -f /etc/nginx/http.d/default.conf

COPY nginx.conf.template /etc/nginx/railway.conf.template
COPY railway-proxy.conf /etc/nginx/railway-proxy.conf
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod +x /usr/local/bin/railway-entrypoint.sh

ENV PORT=8080 \
    CLIENT_PORT=3002 \
    BACKEND_UPSTREAM=backend:3001

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
CMD []
