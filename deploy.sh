#!/bin/bash
set -e

# Non-interactive mode for CI/CD
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

APP_DIR="/home/ubuntu/EMS-Gunicorn"
VENV_DIR="$APP_DIR/venv"
LOG_DIR="$APP_DIR/logs"
SERVICE_FILE="/etc/systemd/system/fastapi.service"
NGINX_FILE="/etc/nginx/sites-available/fastapi"

echo "🚀 Starting FastAPI Deployment..."

# Ensure app directory exists
sudo mkdir -p "$APP_DIR"
sudo chown -R ubuntu:ubuntu "$APP_DIR"

cd "$APP_DIR"

# Always pull latest code if git repo exists
if [ -d ".git" ]; then
    echo "📥 Pulling latest code..."
    git reset --hard
    git pull origin main
fi

# Install required system packages
echo "📦 Installing system dependencies..."
sudo apt update -y
sudo apt install -y python3-pip python3-venv nginx git

# Create logs directory
mkdir -p "$LOG_DIR"

# Setup virtual environment
if [ -d "$VENV_DIR" ]; then
    echo "🔁 Using existing virtual environment..."
else
    echo "🆕 Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

# Create systemd service
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
          --workers 3 \
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

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable fastapi
sudo systemctl restart fastapi

# Configure Nginx
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
