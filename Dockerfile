FROM alpine:3.20

RUN apk add --no-cache ca-certificates

COPY bin/amd64/xray /usr/local/bin/xray
COPY bin/amd64/cloudflared /usr/local/bin/cloudflared
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/xray /usr/local/bin/cloudflared /usr/local/bin/entrypoint.sh

EXPOSE 8001

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
