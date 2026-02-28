#!/bin/bash

# User Data script for App AMI
# Paste into Advanced Details → User Data when launching from App AMI
# Runs as root on first boot — no sudo needed, use absolute paths

# Set DB_HOST (update <DB-PRIVATE-IP> with actual DB private IP before pasting)
export DB_HOST=mongodb://<DB-PRIVATE-IP>:27017/posts

# Seed the database
cd /home/ubuntu/sparta-test-app/app
node seeds/seed.js

# Start app with pm2 as ubuntu user
sudo -u ubuntu bash -c "cd /home/ubuntu/sparta-test-app/app && DB_HOST=$DB_HOST pm2 start app.js --name sparta-app"
