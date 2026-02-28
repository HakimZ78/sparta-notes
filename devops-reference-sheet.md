# DevOps & Cloud Deployment — Quick Reference Sheet

---

## 1. Linux Command Line Essentials

### Navigation & File System

| Command | Description |
|---|---|
| `pwd` | Print working directory (where am I?) |
| `ls` | List files in current directory |
| `ls -la` | List all files including hidden, with details |
| `cd /path` | Change to specified directory |
| `cd ..` | Go up one directory level |
| `cd ~` | Go to home directory |
| `cd -` | Go to previous directory |
| `mkdir dirname` | Create a new directory |
| `rmdir dirname` | Remove empty directory |
| `tree` | Show directory structure as tree |

### File Operations

| Command | Description |
|---|---|
| `touch file.txt` | Create empty file or update timestamp |
| `cp source dest` | Copy file to destination |
| `cp -r dir1 dir2` | Copy directory recursively |
| `mv source dest` | Move or rename file/directory |
| `rm file.txt` | Delete file (no confirmation) |
| `rm -r dirname` | Delete directory and contents |
| `rm -rf dirname` | Force delete without prompts (DANGEROUS) |
| `cat file.txt` | Display entire file contents |
| `less file.txt` | View file with pagination (q to quit) |
| `head -n 20 file` | Show first 20 lines |
| `tail -n 20 file` | Show last 20 lines |
| `tail -f file.log` | Follow file in real-time (logs) |

### File Permissions

Format: `-rwxrwxrwx` = [type][owner][group][others]

r=read(4), w=write(2), x=execute(1)

| Command | Description |
|---|---|
| `chmod 755 file` | rwxr-xr-x (owner full, others read/execute) |
| `chmod 644 file` | rw-r--r-- (owner read/write, others read) |
| `chmod +x file` | Add execute permission for all |
| `chmod u+x file` | Add execute for owner only |
| `chown user file` | Change file owner |
| `chown user:group file` | Change owner and group |

### Text Search & Processing

| Command | Description |
|---|---|
| `grep 'pattern' file` | Search for pattern in file |
| `grep -i 'pattern' file` | Case-insensitive search |
| `grep -r 'pattern' dir/` | Recursive search in directory |
| `grep -v 'pattern' file` | Show lines NOT matching pattern |
| `grep -c 'pattern' file` | Count matching lines |
| `find /path -name '*.txt'` | Find files by name pattern |
| `find /path -type d` | Find directories only |
| `find /path -mtime -7` | Files modified in last 7 days |
| `wc -l file` | Count lines in file |
| `sort file.txt` | Sort lines alphabetically |
| `uniq` | Remove duplicate adjacent lines |
| `sort file \| uniq -c` | Count unique occurrences |

### Piping & Redirection

| Operator | Description |
|---|---|
| `cmd > file` | Redirect output to file (overwrite) |
| `cmd >> file` | Append output to file |
| `cmd 2> file` | Redirect errors to file |
| `cmd &> file` | Redirect both output and errors |
| `cmd1 \| cmd2` | Pipe output of cmd1 to cmd2 |
| `cmd < file` | Use file as input to command |

Example: `cat access.log | grep 'ERROR' | wc -l`

### System Information

| Command | Description |
|---|---|
| `whoami` | Current username |
| `hostname` | Machine name |
| `uname -a` | System information |
| `df -h` | Disk space usage (human readable) |
| `du -sh dirname` | Directory size |
| `free -h` | Memory usage |
| `top` | Live process viewer (q to quit) |
| `htop` | Better process viewer (if installed) |
| `ps aux` | List all running processes |
| `ps aux \| grep nginx` | Find specific process |
| `kill PID` | Terminate process by ID |
| `kill -9 PID` | Force kill process |

### Package Management (Ubuntu/Debian)

| Command | Description |
|---|---|
| `sudo apt update` | Refresh package list (always run first) |
| `sudo apt upgrade` | Upgrade installed packages |
| `sudo apt install pkg` | Install a package |
| `sudo apt remove pkg` | Remove a package |
| `apt search keyword` | Search for packages |
| `apt show pkg` | Show package details |
| `dpkg -l` | List installed packages |

### Service Management (systemd)

| Command | Description |
|---|---|
| `sudo systemctl start nginx` | Start a service |
| `sudo systemctl stop nginx` | Stop a service |
| `sudo systemctl restart nginx` | Restart a service |
| `sudo systemctl status nginx` | Check service status |
| `sudo systemctl enable nginx` | Start service on boot |
| `sudo systemctl disable nginx` | Don't start on boot |
| `journalctl -u nginx` | View service logs |
| `journalctl -u nginx -f` | Follow service logs live |

---

## 2. Bash Scripting

### Script Structure

```bash
#!/bin/bash

# This is a comment

# Variables (no spaces around =)
NAME="World"
COUNT=5

# Using variables (use $)
echo "Hello, $NAME"
echo "Count is: ${COUNT}"
```

### Running Scripts

| Method | Description |
|---|---|
| `chmod +x script.sh` | Make script executable (do once) |
| `./script.sh` | Run script in current directory |
| `bash script.sh` | Run with bash (no chmod needed) |
| `source script.sh` | Run in current shell (affects environment) |

### Variables & Substitution

| Syntax | Description |
|---|---|
| `VAR="value"` | Assign variable (no spaces!) |
| `$VAR` or `${VAR}` | Use variable value |
| `$(command)` | Command substitution (capture output) |
| `${VAR:-default}` | Use default if VAR is unset |
| `$1, $2, $3...` | Script arguments |
| `$#` | Number of arguments |
| `$@` | All arguments as separate words |
| `$?` | Exit code of last command |
| `$$` | Current script's process ID |

### Conditionals

```bash
# If statement
if [[ $COUNT -gt 10 ]]; then
    echo "Greater than 10"
elif [[ $COUNT -eq 10 ]]; then
    echo "Equals 10"
else
    echo "Less than 10"
fi
```

### Comparison Operators

| Numbers | Strings | Files |
|---|---|---|
| `-eq` | `=` or `==` | `-e file` (exists) |
| `-ne` | `!=` | `-f file` (is file) |
| `-gt` | `-z` (empty) | `-d dir` (is directory) |
| `-lt` | `-n` (not empty) | `-r file` (readable) |
| `-ge` | | `-w file` (writable) |
| `-le` | | `-x file` (executable) |

### Loops

```bash
# For loop - iterate over list
for item in apple banana cherry; do
    echo "Fruit: $item"
done

# For loop - iterate over files
for file in *.txt; do
    echo "Processing: $file"
done

# For loop - C-style
for ((i=1; i<=5; i++)); do
    echo "Number: $i"
done

# While loop
COUNT=0
while [[ $COUNT -lt 5 ]]; do
    echo "Count: $COUNT"
    ((COUNT++))
done
```

### Functions

```bash
# Define function
greet() {
    local name=$1  # local variable
    echo "Hello, $name!"
}

# Call function
greet "Alice"

# Function with return value
add_numbers() {
    local result=$(($1 + $2))
    echo $result  # functions 'return' via echo
}

sum=$(add_numbers 5 3)
echo "Sum is: $sum"
```

### Error Handling

```bash
#!/bin/bash
set -e          # Exit on any error
set -u          # Error on undefined variables
set -o pipefail # Catch errors in pipes

# Check command success
if ! command -v nginx &> /dev/null; then
    echo "nginx not installed"
    exit 1
fi

# Exit codes
exit 0  # Success
exit 1  # General error
```

### Useful Patterns

```bash
# Read file line by line
while IFS= read -r line; do
    echo "Line: $line"
done < input.txt

# Check if root
if [[ $EUID -ne 0 ]]; then
    echo "Must run as root"
    exit 1
fi

# Timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
echo "backup_$TIMESTAMP.tar.gz"
```

---

## 3. Software Configuration

### Environment Variables

| Command | Description |
|---|---|
| `echo $PATH` | View PATH variable |
| `export VAR=value` | Set variable for current session |
| `env` | Show all environment variables |
| `printenv VAR` | Print specific variable |
| `unset VAR` | Remove variable |

Persistent variables: Add to `~/.bashrc` or `~/.profile`

### Nginx Web Server

| Path/Command | Description |
|---|---|
| `/etc/nginx/nginx.conf` | Main configuration file |
| `/etc/nginx/sites-available/` | Site configurations |
| `/etc/nginx/sites-enabled/` | Active sites (symlinks) |
| `/var/www/html/` | Default web root |
| `sudo nginx -t` | Test configuration syntax |
| `sudo systemctl reload nginx` | Reload config without downtime |

### Basic Nginx Site Config

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/myapp;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### Node.js Setup

```bash
# Install Node.js via NodeSource
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version
npm --version

# Install dependencies from package.json
npm install

# Run application
npm start

# Run in background with PM2
sudo npm install -g pm2
pm2 start app.js
pm2 status
pm2 logs
```

### Python Setup

```bash
# Python 3 is usually pre-installed
python3 --version

# Install pip
sudo apt install python3-pip

# Install virtualenv
pip3 install virtualenv

# Create virtual environment
python3 -m venv myenv

# Activate environment
source myenv/bin/activate

# Install requirements
pip install -r requirements.txt

# Deactivate
deactivate
```

---

## 4. AWS Cloud Fundamentals

### Core Concepts

| Term | Description |
|---|---|
| Region | Geographic area (e.g., eu-west-2 = London) |
| Availability Zone (AZ) | Isolated data centre within a region |
| EC2 | Virtual servers (Elastic Compute Cloud) |
| S3 | Object storage (Simple Storage Service) |
| VPC | Virtual network (Virtual Private Cloud) |
| Security Group | Virtual firewall for EC2 instances |
| IAM | Identity and Access Management |
| AMI | Amazon Machine Image (server template) |

### EC2 Instance Types

| Type | Use Case |
|---|---|
| t2.micro | Free tier, testing, small workloads |
| t3.small/medium | General purpose, web servers |
| m5/m6i | Balanced compute, memory, networking |
| c5/c6i | Compute-intensive workloads |
| r5/r6i | Memory-intensive applications |

### SSH Connection

```bash
# Set key permissions (required)
chmod 400 mykey.pem

# Connect to EC2 instance
ssh -i mykey.pem ubuntu@<public-ip>

# Copy file to EC2
scp -i mykey.pem file.txt ubuntu@<public-ip>:~/

# Copy from EC2
scp -i mykey.pem ubuntu@<public-ip>:~/file.txt ./

# Copy directory
scp -i mykey.pem -r mydir ubuntu@<public-ip>:~/
```

### Security Groups (Firewall Rules)

| Type | Port | Use |
|---|---|---|
| SSH | 22 | Remote terminal access |
| HTTP | 80 | Web traffic (unencrypted) |
| HTTPS | 443 | Web traffic (encrypted) |
| Custom TCP | 3000 | Node.js default port |
| Custom TCP | 8080 | Alternative web port |

Tip: Restrict SSH (port 22) to your IP, not 0.0.0.0/0

### AWS CLI Commands

```bash
# Configure CLI
aws configure

# List EC2 instances
aws ec2 describe-instances

# Start/stop instance
aws ec2 start-instances --instance-ids i-1234567890
aws ec2 stop-instances --instance-ids i-1234567890

# List S3 buckets
aws s3 ls

# Copy to S3
aws s3 cp file.txt s3://mybucket/

# Sync directory to S3
aws s3 sync ./mydir s3://mybucket/mydir
```

---

## 5. Automated Deployment

### User Data Scripts

User Data runs automatically when EC2 instance first launches.

```bash
#!/bin/bash

# Update system
apt update -y
apt upgrade -y

# Install nginx
apt install nginx -y
systemctl start nginx
systemctl enable nginx

# Deploy application
cd /var/www/html
git clone https://github.com/user/repo.git .

# Set permissions
chown -R www-data:www-data /var/www/html
```

User Data logs: `/var/log/cloud-init-output.log`

### Complete Deployment Script Example

```bash
#!/bin/bash
set -e  # Exit on error

# Variables
APP_DIR=/var/www/myapp
REPO_URL=https://github.com/user/myapp.git

# System updates
apt update -y && apt upgrade -y

# Install dependencies
apt install -y nginx git
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
npm install -g pm2

# Clone application
git clone $REPO_URL $APP_DIR
cd $APP_DIR

# Install app dependencies
npm install

# Start application
pm2 start app.js --name myapp
pm2 startup systemd
pm2 save

# Configure nginx reverse proxy
cat > /etc/nginx/sites-available/myapp << 'EOF'
server {
    listen 80;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
}
EOF

ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

echo "Deployment complete!"
```

### AMIs (Amazon Machine Images)

AMIs are templates containing OS, software, and configurations.

| Action | Description |
|---|---|
| Create AMI | EC2 Console > Actions > Image > Create Image |
| Launch from AMI | EC2 Console > AMIs > Select > Launch |
| Share AMI | Actions > Modify Image Permissions |
| Copy to region | Actions > Copy AMI |

### AMI Workflow

1. Launch base EC2 instance (e.g., Ubuntu)
2. SSH in and configure: install software, deploy app
3. Test everything works
4. Create AMI from configured instance
5. Launch new instances from your custom AMI
6. New instances start pre-configured!

### Debugging Deployment Issues

| Check | Command |
|---|---|
| User Data logs | `cat /var/log/cloud-init-output.log` |
| System logs | `journalctl -xe` |
| Nginx logs | `cat /var/log/nginx/error.log` |
| Nginx status | `sudo systemctl status nginx` |
| App process running | `ps aux \| grep node` |
| Port in use | `sudo lsof -i :80` |
| Network connectivity | `curl -I http://localhost` |
| Security group | Check inbound rules in AWS console |

---

## 6. Quick Troubleshooting

### Common Issues & Solutions

| Problem | Solution |
|---|---|
| Permission denied | Use sudo or check file permissions (chmod) |
| Command not found | Install package or check PATH |
| Connection refused | Check security group, service running? |
| Connection timeout | Security group or instance not running |
| 502 Bad Gateway | Backend app not running, check PM2/Node |
| Can't SSH | Key permissions (chmod 400), security group port 22 |
| apt update fails | Check internet, DNS, or apt sources |
| Script won't run | Add shebang, chmod +x, check line endings |
| nginx won't start | Run nginx -t, check config syntax |

### Essential Debug Commands

```bash
# What's using a port?
sudo lsof -i :80
sudo netstat -tlnp | grep 80

# Is service running?
systemctl status nginx
ps aux | grep nginx

# What's in the logs?
tail -100 /var/log/nginx/error.log
journalctl -u nginx --since '1 hour ago'

# Can I reach the internet?
ping google.com
curl -I https://google.com

# DNS working?
nslookup google.com

# What's my IP?
curl ifconfig.me
```
