#!/usr/bin/env bash
set -euo pipefail

SERVER_HOST="${SERVER_HOST:-54.150.9.209}"
SERVER_USER="${SERVER_USER:-ubuntu}"
APP_DIR="${APP_DIR:-/opt/interview-bank-server}"
ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:?Set ADMIN_PASSWORD before deploy}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCHIVE="/tmp/interview-bank-server.tar.gz"

tar \
  --exclude="deploy" \
  --exclude="node_modules" \
  -czf "$ARCHIVE" \
  -C "$ROOT_DIR" \
  .

scp "$ARCHIVE" "$SERVER_USER@$SERVER_HOST:/tmp/interview-bank-server.tar.gz"
scp "$ROOT_DIR/deploy/interview-bank.service" "$SERVER_USER@$SERVER_HOST:/tmp/interview-bank.service"
scp "$ROOT_DIR/deploy/nginx-interview-bank.conf" "$SERVER_USER@$SERVER_HOST:/tmp/nginx-interview-bank.conf"

ssh "$SERVER_USER@$SERVER_HOST" \
  "APP_DIR='$APP_DIR' ADMIN_USERNAME='$ADMIN_USERNAME' ADMIN_PASSWORD='$ADMIN_PASSWORD' bash -s" <<'REMOTE'
set -euo pipefail

if ! command -v node >/dev/null 2>&1 || ! command -v sqlite3 >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y nodejs npm sqlite3
fi

sudo mkdir -p "$APP_DIR"
sudo tar -xzf /tmp/interview-bank-server.tar.gz -C "$APP_DIR"
sudo chown -R www-data:www-data "$APP_DIR"

sudo mv /tmp/interview-bank.service /etc/systemd/system/interview-bank.service
sudo sed -i "s/^Environment=ADMIN_USERNAME=.*/Environment=ADMIN_USERNAME=$ADMIN_USERNAME/" /etc/systemd/system/interview-bank.service
sudo sed -i "s/^Environment=ADMIN_PASSWORD=.*/Environment=ADMIN_PASSWORD=$ADMIN_PASSWORD/" /etc/systemd/system/interview-bank.service
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
curl -fsS http://127.0.0.1:8080/api/health
REMOTE

echo
echo "Deploy finished. Verify:"
echo "  http://$SERVER_HOST/api/health"
echo "  http://$SERVER_HOST/admin"
