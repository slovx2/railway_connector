FROM alpine:3.20

ARG TARGETARCH

RUN apk add --no-cache ca-certificates

COPY bin/ /opt/bin/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN set -eu; \
    arch="${TARGETARCH:-$(uname -m)}"; \
    case "$arch" in \
      amd64|x86_64) bin_arch="amd64" ;; \
      arm64|aarch64) bin_arch="arm64" ;; \
      *) echo "Unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    cp "/opt/bin/${bin_arch}/xray" /usr/local/bin/xray; \
    cp "/opt/bin/${bin_arch}/cloudflared" /usr/local/bin/cloudflared; \
    chmod +x /usr/local/bin/xray /usr/local/bin/cloudflared /usr/local/bin/entrypoint.sh; \
    rm -rf /opt/bin

EXPOSE 8001

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
