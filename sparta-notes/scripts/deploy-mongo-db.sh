#!/bin/bash

# Update and upgrade
sudo apt update -y

sudo apt upgrade -y

# Install dependencies
sudo apt install gnupg curl -y

# Import MongoDB GPG key-to verify packages
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

# Add MongoDB repository to APT sources list

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Update apt with new repo
sudo apt update -y

sudo apt install -y mongodb-org=7.0.6 mongodb-org-database=7.0.6 mongodb-org-server=7.0.6 mongodb-mongosh=2.1.5 mongodb-org-mongos=7.0.6 mongodb-org-tools=7.0.6

# make sure sed is installed (it should be by default)
sudo apt install sed -y

# Change bindIp from 127.0.0.1 to 0.0.0.0 (accept connections from app instance)
sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

# Start and enable MongoDB
# We need to restart to apply the bindIp change
sudo systemctl restart mongod 
sudo systemctl enable mongod # Allows AMI to start MongoDB on boot (otherwise it would only start when we run this script)