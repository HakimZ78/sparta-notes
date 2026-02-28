#!/bin/bash
apt update -y
apt install -y nginx
systemctl start nginx
systemctl enable nginx

cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Automated Deployment</title></head>
<body>
    <h1>This was deployed automatically!</h1>
    <p>No manual SSH required</p>
</body>
</html>
EOF