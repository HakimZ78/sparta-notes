#!/bin/bash

# Update and upgrade
sudo apt update -y

sudo apt upgrade -y

# Install Nginx and configure reverse proxy
sudo apt install nginx -y

sudo systemctl enable nginx

sudo tee /etc/nginx/sites-available/default > /dev/null << 'EOF'
server {
    listen 80;

    location / {
        proxy_pass http://localhost:3000;
    }
}
EOF

sudo systemctl restart nginx

# Install Node.js 20.x
sudo bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -"

sudo apt install nodejs -y

# Install pm2 globally
sudo npm install -g pm2

# kill any existing pm2 processes
pm2 kill

# Clone the app from GitHub
git clone https://github.com/HakimZ78/sparta-test-app.git ~/sparta-test-app

# Install dependencies and start with pm2
cd ~/sparta-test-app/app

sudo npm install

pm2 start app.js --name "sparta-app"