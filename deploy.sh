#!/bin/bash
set -e

if [ -d "venv" ]; then
  echo "Virtual environment exists. Pulling latest changes..."
  git pull origin main
  source venv/bin/activate
  pip install -r requirements.txt
else
  echo "First time setup..."

  sudo apt update
  sudo apt install -y python3-pip python3-venv nginx

  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt

  sudo tee /etc/systemd/system/fastapi.service > /dev/null << 'SERVICEEOF'
[Unit]
Description=FastAPI App (Gunicorn)
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/EMS-Gunicorn
ExecStart=/home/ubuntu/EMS-Gunicorn/venv/bin/gunicorn main:app \
          -k uvicorn.workers.UvicornWorker \
          -w 4 \
          -b 127.0.0.1:8000
Restart=always

[Install]
WantedBy=multi-user.target
SERVICEEOF

  sudo systemctl daemon-reload
  sudo systemctl enable fastapi
  sudo systemctl start fastapi

  sudo tee /etc/nginx/sites-available/fastapi > /dev/null << 'NGINXEOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINXEOF

  sudo ln -sf /etc/nginx/sites-available/fastapi /etc/nginx/sites-enabled/fastapi
  sudo rm -f /etc/nginx/sites-enabled/default
  sudo nginx -t
  sudo systemctl restart nginx
fi

sudo systemctl restart fastapi