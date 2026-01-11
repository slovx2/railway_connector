#!/bin/sh
set -eu

UUID="${UUID:-9afd1229-b893-40c1-84dd-51e7ce204913}"
ARGO_PORT="${ARGO_PORT:-8001}"
WS_PATH="${WS_PATH:-/vless-argo}"
XRAY_LOG_LEVEL="${XRAY_LOG_LEVEL:-warning}"
ARGO_DOMAIN="${ARGO_DOMAIN:-}"
ARGO_AUTH="${ARGO_AUTH:-}"
CFIP="${CFIP:-$ARGO_DOMAIN}"
CFPORT="${CFPORT:-443}"
NAME="${NAME:-vless}"

if [ -z "$ARGO_AUTH" ] || [ -z "$ARGO_DOMAIN" ]; then
  echo "ARGO_AUTH and ARGO_DOMAIN are required" >&2
  exit 1
fi

case "$WS_PATH" in
  /*) ;;
  *) WS_PATH="/$WS_PATH" ;;
esac

mkdir -p /etc/xray
cat > /etc/xray/config.json <<EOF
{
  "log": { "loglevel": "${XRAY_LOG_LEVEL}" },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": ${ARGO_PORT},
      "protocol": "vless",
      "settings": { "clients": [{ "id": "${UUID}" }], "decryption": "none" },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "${WS_PATH}" } }
    }
  ],
  "outbounds": [
    { "protocol": "freedom" }
  ]
}
EOF

/usr/local/bin/xray -config /etc/xray/config.json &
XRAY_PID=$!

/usr/local/bin/cloudflared tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token "${ARGO_AUTH}" &
CF_PID=$!

WS_PATH_ENCODED="$(printf '%s' "$WS_PATH" | sed 's#/#%2F#g')"
VLESS_LINK="vless://${UUID}@${CFIP}:${CFPORT}?encryption=none&security=tls&sni=${ARGO_DOMAIN}&fp=firefox&type=ws&host=${ARGO_DOMAIN}&path=${WS_PATH_ENCODED}#${NAME}"
echo "VLESS_LINK=${VLESS_LINK}"

PIDS="$XRAY_PID $CF_PID"
while true; do
  for PID in $PIDS; do
    if ! kill -0 "$PID" 2>/dev/null; then
      if [ "$PID" = "$XRAY_PID" ]; then
        echo "xray exited: $PID" >&2
      else
        echo "cloudflared exited: $PID" >&2
      fi
      exit 1
    fi
  done
  sleep 1
done
