#!/bin/bash
set -e

APP_DIR="/home/ubuntu/EMS-Gunicorn"
VENV_DIR="$APP_DIR/venv"
LOG_DIR="$APP_DIR/logs"

# 1️⃣ Create logs directory
mkdir -p "$LOG_DIR"

# 2️⃣ Activate or create virtual environment
if [ -d "$VENV_DIR" ]; then
    echo "Virtual environment exists. Pulling latest changes..."
    cd "$APP_DIR"
    git pull origin main
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip setuptools wheel
    pip install -r requirements.txt
else
    echo "First time setup..."
    sudo apt update
    sudo apt install -y python3-pip python3-venv nginx git

    cd "$APP_DIR"
    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip setuptools wheel
    pip install -r requirements.txt
fi

# 3️⃣ Create systemd service for FastAPI (Gunicorn)
sudo tee /etc/systemd/system/fastapi.service > /dev/null <<EOF
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
          --bind 0.0.0.0:8000 \
          --access-logfile $LOG_DIR/access.log \
          --error-logfile $LOG_DIR/error.log
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start service
sudo systemctl daemon-reload
sudo systemctl enable fastapi
sudo systemctl restart fastapi

# 4️⃣ Configure Nginx as reverse proxy
sudo tee /etc/nginx/sites-available/fastapi > /dev/null <<EOF
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

sudo ln -sf /etc/nginx/sites-available/fastapi /etc/nginx/sites-enabled/fastapi
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

echo "✅ FastAPI deployment completed!"
echo "You can now access your app at: http://<EC2_PUBLIC_IP>/docs"
echo "Logs are available at $LOG_DIR/"
