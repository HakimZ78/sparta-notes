#!/bin/bash

# User Data script for DB AMI
# Paste into Advanced Details → User Data when launching from DB AMI
# Runs as root on first boot — no sudo needed

# MongoDB should auto-start if 'systemctl enable mongod' was run before creating AMI
# This script ensures it's running in case it didn't start automatically

systemctl start mongod
systemctl enable mongod
