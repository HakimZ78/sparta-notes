#!/bin/bash
# Refreshes package list (latest version)
sudo apt update -y

# Installs newest version of package
sudo apt upgrade -y

# Installs nginx web server
sudo apt install nginx -y

# Stop nginx service then start it again to ensure it is running
sudo systemctl restart nginx 

# Enable nginx to start on boot
sudo systemctl enable nginx
