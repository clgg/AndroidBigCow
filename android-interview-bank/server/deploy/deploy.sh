#!/usr/bin/env bash
set -euo pipefail

SERVER_HOST="${SERVER_HOST:-54.150.9.209}"
SERVER_USER="${SERVER_USER:-ubuntu}"
APP_DIR="${APP_DIR:-/opt/interview-bank-server}"
APP_PORT="${APP_PORT:-8090}"
ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"
SSH_KEY="${SSH_KEY:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCHIVE="/tmp/interview-bank-server.tar.gz"
SSH_ARGS=()
if [ -n "$SSH_KEY" ]; then
  SSH_ARGS=(-i "$SSH_KEY")
fi

tar \
  --exclude="deploy" \
  --exclude="node_modules" \
  --exclude="data/questions.db" \
  --exclude="data/questions.db-*" \
  --exclude="data/progress-sync.json" \
  --exclude="data/tts-config.json" \
  --exclude="data/audio" \
  -czf "$ARCHIVE" \
  -C "$ROOT_DIR" \
  .

scp "${SSH_ARGS[@]}" "$ARCHIVE" "$SERVER_USER@$SERVER_HOST:/tmp/interview-bank-server.tar.gz"
scp "${SSH_ARGS[@]}" "$ROOT_DIR/deploy/interview-bank.service" "$SERVER_USER@$SERVER_HOST:/tmp/interview-bank.service"
scp "${SSH_ARGS[@]}" "$ROOT_DIR/deploy/nginx-interview-bank.conf" "$SERVER_USER@$SERVER_HOST:/tmp/nginx-interview-bank.conf"

ssh "${SSH_ARGS[@]}" "$SERVER_USER@$SERVER_HOST" \
  "APP_DIR='$APP_DIR' APP_PORT='$APP_PORT' ADMIN_USERNAME='$ADMIN_USERNAME' ADMIN_PASSWORD='$ADMIN_PASSWORD' bash -s" <<'REMOTE'
set -euo pipefail

if ! command -v node >/dev/null 2>&1 || ! command -v sqlite3 >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y nodejs npm sqlite3
fi

sudo mkdir -p "$APP_DIR"
sudo tar -xzf /tmp/interview-bank-server.tar.gz -C "$APP_DIR"
sudo chown -R www-data:www-data "$APP_DIR"

if [ -z "$ADMIN_PASSWORD" ] && [ -f /etc/systemd/system/interview-bank.service ]; then
  ADMIN_PASSWORD="$(sudo sed -n 's/^Environment=ADMIN_PASSWORD=//p' /etc/systemd/system/interview-bank.service | tail -n 1)"
fi

sudo mv /tmp/interview-bank.service /etc/systemd/system/interview-bank.service
sudo sed -i "s/^Environment=PORT=.*/Environment=PORT=$APP_PORT/" /etc/systemd/system/interview-bank.service
sudo sed -i "s#^Environment=PUBLIC_BASE_URL=.*#Environment=PUBLIC_BASE_URL=http://localhost:$APP_PORT#" /etc/systemd/system/interview-bank.service
sudo sed -i "s/^Environment=ADMIN_USERNAME=.*/Environment=ADMIN_USERNAME=$ADMIN_USERNAME/" /etc/systemd/system/interview-bank.service
if [ -n "$ADMIN_PASSWORD" ]; then
  sudo sed -i "s/^Environment=ADMIN_PASSWORD=.*/Environment=ADMIN_PASSWORD=$ADMIN_PASSWORD/" /etc/systemd/system/interview-bank.service
fi
sudo systemctl daemon-reload
sudo systemctl enable interview-bank
sudo systemctl restart interview-bank

if [ -f /etc/nginx/sites-available/default ]; then
  if ! sudo grep -q "interview-bank paths" /etc/nginx/sites-available/default; then
    sudo sed -i "/server_name _;/r /tmp/nginx-interview-bank.conf" /etc/nginx/sites-available/default
  fi
elif [ -f /etc/nginx/conf.d/default.conf ]; then
  if ! sudo grep -q "interview-bank paths" /etc/nginx/conf.d/default.conf; then
    sudo sed -i "/server_name _;/r /tmp/nginx-interview-bank.conf" /etc/nginx/conf.d/default.conf
  fi
else
  echo "Nginx default server config was not found. Add /tmp/nginx-interview-bank.conf into your server block manually."
fi

sudo nginx -t
sudo systemctl reload nginx
HEALTH_OK=0
for _ in $(seq 1 10); do
  if curl -fsS "http://127.0.0.1:$APP_PORT/api/health"; then
    HEALTH_OK=1
    break
  fi
  sleep 1
done
if [ "$HEALTH_OK" -ne 1 ]; then
  echo "Health check failed: http://127.0.0.1:$APP_PORT/api/health" >&2
  exit 1
fi
REMOTE

echo
echo "Deploy finished. Verify:"
echo "  http://$SERVER_HOST/interview/api/health"
echo "  http://$SERVER_HOST/admin"
