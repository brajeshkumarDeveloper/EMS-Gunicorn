#!/bin/bash
set -euo pipefail

# -----------------------------
# CONFIG
# -----------------------------
APP_DIR="/home/ubuntu/EMS-Gunicorn"
VENV_DIR="$APP_DIR/venv"
LOG_DIR="$APP_DIR/logs"
SERVICE_FILE="/etc/systemd/system/fastapi.service"
NGINX_FILE="/etc/nginx/sites-available/fastapi"

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

echo "🚀 Starting FastAPI Deployment..."

# -----------------------------
# INSTALL SYSTEM DEPENDENCIES (only if missing)
# -----------------------------
if ! command -v nginx &> /dev/null; then
    echo "📦 Installing system dependencies..."
    sudo apt update
    sudo apt install -y python3-venv python3-pip nginx git curl
fi

# -----------------------------
# PREPARE APP DIRECTORY
# -----------------------------
sudo mkdir -p "$APP_DIR"
sudo chown -R ubuntu:ubuntu "$APP_DIR"
cd "$APP_DIR"

# -----------------------------
# GIT UPDATE
# -----------------------------
if [ -d ".git" ]; then
    echo "📥 Pulling latest code..."
    git fetch origin
    git reset --hard origin/main
fi

# -----------------------------
# SETUP LOG DIRECTORY
# -----------------------------
mkdir -p "$LOG_DIR"

# -----------------------------
# SETUP VIRTUAL ENVIRONMENT
# -----------------------------
if [ ! -d "$VENV_DIR" ]; then
    echo "🆕 Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

echo "⬆️ Upgrading pip & fixing setuptools compatibility..."
pip install --upgrade pip
pip install "setuptools<70" wheel

echo "📦 Installing Python dependencies..."
pip install -r requirements.txt

# -----------------------------
# CREATE SYSTEMD SERVICE
# -----------------------------
echo "⚙️ Configuring systemd service..."

sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=FastAPI App (Gunicorn)
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=$APP_DIR
Environment="PATH=$VENV_DIR/bin"
ExecStart=$VENV_DIR/bin/gunicorn main:app \
          --workers 2 \
          --worker-class uvicorn.workers.UvicornWorker \
          --bind 127.0.0.1:8000 \
          --timeout 60 \
          --graceful-timeout 30 \
          --keep-alive 5 \
          --access-logfile $LOG_DIR/access.log \
          --error-logfile $LOG_DIR/error.log
Restart=always
RestartSec=5
KillSignal=SIGQUIT
TimeoutStopSec=30
PrivateTmp=true
ProtectSystem=full
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable fastapi
sudo systemctl restart fastapi

# -----------------------------
# HEALTH CHECK
# -----------------------------
echo "🔎 Checking application health..."
sleep 3
curl -f http://127.0.0.1:8000/docs > /dev/null || {
    echo "❌ App failed to start!"
    sudo systemctl status fastapi
    exit 1
}

# -----------------------------
# CONFIGURE NGINX
# -----------------------------
echo "🌐 Configuring Nginx..."

sudo tee "$NGINX_FILE" > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 60;
        client_max_body_size 20M;
    }
}
EOF

sudo ln -sf "$NGINX_FILE" /etc/nginx/sites-enabled/fastapi
sudo rm -f /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl restart nginx

echo "✅ Deployment Successful!"
echo "🌍 Access your app at: http://<EC2_PUBLIC_IP>/docs"
echo "📄 Logs available at: $LOG_DIR/"
