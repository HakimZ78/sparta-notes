# Day 2 - Networking, App Deployment & DevOps

---

## NACLs (Network Access Control Lists)

- **Stateless** firewall at the **subnet level**
- Must explicitly allow both inbound AND outbound traffic
- Supports **allow** and **deny** rules (unlike Security Groups which are allow-only)
- Rules evaluated in order — lowest rule number first
- Default NACL allows all traffic

### NACLs vs Security Groups

| Feature | Security Group | NACL |
|---|---|---|
| Level | Instance | Subnet |
| Stateful/Stateless | Stateful | Stateless |
| Rules | Allow only | Allow and Deny |
| Default | Denies all inbound | Allows all traffic |
| Use case | Per-instance control | Broad subnet-level guardrails |

**In practice**: Security Groups do most of the work. NACLs are an extra layer for defence-in-depth.

---

## AWS Networking Notes

- **IP addresses in AWS are dynamic** — the public IP changes every time you stop/start an instance
  - You can pay for an **Elastic IP** (static IP) if you need it to stay the same
- **VPC uses private IPs** — instances communicate internally via private IPs (e.g. `172.31.48.131`)
- **Connect from your .ssh folder**:
  ```bash
  ssh -i "se-zaehid-key-pair.pem" ubuntu@ec2-52-30-6-173.eu-west-1.compute.amazonaws.com
  ```
  - Use the example connect command from the AWS console

---

## Linux Notes

- `cat /etc/shells` — lists all available shells on the system (e.g. `/bin/bash`, `/bin/zsh`)
- **Idempotency** — running the same command/script multiple times produces the same result. Important for automation — your scripts shouldn't break if run twice
- `source deploy-nginx.sh` — runs a script in the current shell session (vs `./script.sh` which runs in a subshell)

---

## Getting App Code onto EC2

### What any app deployment needs
- **App Code** — how do we get it onto the instance?
- **Linux** — the operating system
- **Nginx** — web server / reverse proxy
- **Node.js 20.x** — runtime for the application
- **Ports 22, 80 & 3000 open** — SSH, HTTP, and the app port (or wherever the dev has hardcoded)

### Two main methods

#### Method 1: SCP (Secure Copy) — using your SSH key

Copy files directly from your local machine to the instance:

```bash
# Copy a folder recursively
scp -i ~/.ssh/se-zaehid-key-pair.pem -r ~/Documents/MSc-CS/sparta/sparta_app/nodejs20-se-test-app-2025/app ubuntu@<PUBLIC-IP>:~/

# Copy a zip file
scp -i ~/.ssh/se-zaehid-key-pair.pem "nodejs20-se-test-app-2025.zip" ubuntu@<PUBLIC-IP>:~
```

| Part | Meaning |
|---|---|
| `scp` | Secure Copy — transfers files over SSH |
| `-i ~/.ssh/se-zaehid-key-pair.pem` | Identity file — your private key to authenticate |
| `-r` | Recursive — copy the entire folder and everything inside it |
| `~/Documents/.../app` | Source — the app folder on your local Mac |
| `ubuntu@<PUBLIC-IP>` | Destination user & host |
| `:~/` | Destination path — home directory (`/home/ubuntu/`) on the instance |

- **`scp`** works for both zip files and unzipped files/folders
- For folders, use the `-r` flag
- For syncing changes (only sending diffs), use **`rsync`** instead

#### Method 2: Git Clone — pull from GitHub onto the instance

Push code to GitHub first, then clone it on the instance:

```bash
# On your Mac — push to GitHub
cd ~/Documents/MSc-CS/sparta/sparta_app/nodejs20-se-test-app-2025
git init && git add . && git commit -m "Initial commit"
gh repo create sparta-test-app --public --source=. --push

# On your EC2 instance
git clone https://github.com/<your-username>/sparta-test-app.git
```

---

## DevOps — The Bigger Picture

### What is DevOps?

**Dev**elopment + **Op**erations — bridging the gap between writing code and running it in production.

### DevOps across the SDLC

```
Plan → Code → Build → Test → Release → Deploy → Operate → Monitor
  ↑                                                          │
  └──────────────── Feedback loop ◄──────────────────────────┘
```

DevOps is about making the **entire SDLC** efficient, effective, and robust:

- **Automation** — remove manual steps at every stage
- **Standardisation** — consistent environments, consistent processes
- **Documentation** — clear, up-to-date, version-controlled docs
- **Avoid vendor lock-in** — don't tie yourself to one provider unnecessarily
- **Security best practices** — shift security left, embed it in the pipeline
- **Uptime** — reliable systems that recover from failure automatically

### The deployment progression

```
Manual (Day 1)  →  Scripted (Day 2)  →  CI/CD  →  Infrastructure as Code
     ↑                  ↑                              ↑
  SSH + type         bash scripts                 fully automated
  commands           scp/git                      no human involved
```

From this point on, the course is about **improving the deployment process** — each step removes more manual work.

### Containers

- Containers (e.g. Docker) allow you to break down environments into **smaller, isolated segments**
- Instead of one big server running everything, each service runs in its own container
- More portable, more scalable, easier to manage

---

## LAMP Stack (mentioned)

- **L**inux, **A**pache, **M**ySQL, **P**HP — a traditional web server stack
- The equivalent of what you're building is more of a **LEMP** stack (Linux, Nginx, Express/Node, MongoDB) or similar

---

## Task 1 (Optional): Redo Manual Deployment on a Fresh EC2 Instance

### Prerequisites
- Launch a fresh EC2 instance:
  - AMI: Ubuntu 24.04
  - Instance type: t3.micro
  - Key pair: `se-zaehid-key-pair`
  - Security Group: ports **22**, **80**, **3000** open

### Step 1: Copy the app code from your local machine
```bash
# From your Mac terminal (NOT inside the instance)
scp -i ~/.ssh/se-zaehid-key-pair.pem "nodejs20-se-test-app-2025.zip" ubuntu@54.171.56.176:~
```

### Step 2: SSH into your instance
```bash
ssh -i ~/.ssh/se-zaehid-key-pair.pem ubuntu@54.171.56.176
```

### Step 3: Run the deployment commands
```bash
# Update and upgrade
sudo apt update -y
sudo apt upgrade -y

# Install unzip and extract app
sudo apt install unzip -y
sudo unzip nodejs20-se-test-app-2025.zip

# Install Nginx
sudo apt install nginx -y
sudo systemctl status nginx   # check it's running, press q to exit

# Install Node.js 20.x
sudo bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -"
sudo apt install nodejs -y
node -v   # verify v20.x.x

# Navigate to app and install dependencies
cd nodejs20-se-test-app-2025/app
sudo npm install

# Start the app
npm start app.js
```

### Step 4: Verify
- Visit `http://54.171.56.176:3000` in your browser
- You should see the Sparta test app

---

## Task 2: Write a Bash Script to Deploy the Sparta App

This is the key task — automate everything from Task 1 into a single script, using **git clone** instead of scp.

### Prerequisites
- App code pushed to a GitHub repo (public)
- Fresh EC2 instance with ports 22, 80, 3000 open

### The deployment script (`deploy-sparta-app.sh`)

```bash
#!/bin/bash

# Update and upgrade
sudo apt update -y
sudo apt upgrade -y

# Install Nginx
sudo apt install nginx -y
sudo systemctl enable nginx

# Install Node.js 20.x
sudo bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -"
sudo apt install nodejs -y

# Clone the app from GitHub
git clone https://github.com/<HakimZ78>/sparta-test-app.git ~/sparta-test-app

# Install dependencies
cd ~/sparta-test-app/app
sudo npm install

# Start the app
npm start app.js
```

### How to use this script

**Option A: Create it locally and scp it over**
```bash
# From your Mac — copy script to instance
scp -i ~/.ssh/se-zaehid-key-pair.pem deploy-sparta-app.sh ubuntu@54.171.56.176:~
#full path
scp -i ~/.ssh/se-zaehid-key-pair.pem ~/Documents/MSc-CS/sparta/sparta-notes/scripts/deploy-sparta-app.sh ubuntu@54.171.56.176:~
# SSH in
ssh -i ~/.ssh/se-zaehid-key-pair.pem ubuntu@54.171.56.176

# Make it executable and run
chmod +x deploy-sparta-app.sh
./deploy-sparta-app.sh
```

**Option B: Create it directly on the instance**
```bash
# SSH in first, then:
nano deploy-sparta-app.sh
# Paste the script, Ctrl+O to save, Ctrl+X to exit
chmod +x deploy-sparta-app.sh
./deploy-sparta-app.sh
```

**Option C: Paste into EC2 User Data at launch**
- No SSH needed at all — runs automatically on first boot
- Remove `sudo` from commands (User Data runs as root)

### Bonus: Run the app in the background using pm2

When you run `npm start app.js`, the app takes over your terminal. To run it in the **background**, use **pm2** — a Node.js process manager.

#### What is pm2?
- A process manager for Node.js applications
- Keeps your app running in the background
- Automatically restarts it if it crashes
- You keep terminal access while the app runs

#### Install and use pm2

```bash
# Install pm2 globally
sudo npm install -g pm2

# Start the app with pm2 (instead of npm start)
cd ~/sparta-test-app/app
pm2 start app.js --name "sparta-app"

# Useful pm2 commands
pm2 status              # see running processes
pm2 logs sparta-app     # view app logs
pm2 stop sparta-app     # stop the app
pm2 restart sparta-app  # restart the app
pm2 delete sparta-app   # remove from pm2
```

#### Updated script with pm2

```bash
#!/bin/bash

# Update and upgrade
sudo apt update -y
sudo apt upgrade -y

# Install Nginx
sudo apt install nginx -y
sudo systemctl enable nginx

# Install Node.js 20.x
sudo bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -"
sudo apt install nodejs -y

# Install pm2 globally
sudo npm install -g pm2

# Clone the app from GitHub
git clone https://github.com/HakimZ78/sparta-test-app.git ~/sparta-test-app

# Install dependencies and start with pm2
cd ~/sparta-test-app/app
sudo npm install
pm2 start app.js --name "sparta-app"
```

Now after the script runs, your terminal is free and the app stays running.

---

## Task 3 (Bonus): Implement a Reverse Proxy with Nginx

### What is a reverse proxy?

Right now users visit `http://54.171.56.176:3000` to see your app. With a reverse proxy, they visit `http://54.171.56.176` (port 80, no :3000 needed). Nginx sits in front and forwards requests to your app:

```
User → http://54.171.56.176 (port 80) → Nginx → localhost:3000 → Node.js app
```

### Why?
- Users don't need to type `:3000`
- Port 80 is the HTTP default — cleaner URLs
- Nginx handles the public-facing connection, your app stays internal
- Production standard — enables SSL, load balancing, caching later

### Step 1: Do it manually first

SSH into your instance (app should already be running via pm2 or in another terminal).

**Edit the Nginx config:**
```bash
sudo nano /etc/nginx/sites-available/default
```

**Find the `location /` block** and replace it with:
```nginx
server {
    listen 80;

    location / {
        proxy_pass http://localhost:3000;
    }
}
```

In nano:
- Delete the existing content: hold `Ctrl+K` to delete lines
- Paste the new config
- `Ctrl+O` → Enter to save
- `Ctrl+X` to exit

**Test and restart Nginx:**
```bash
sudo nginx -t              # test config for syntax errors
sudo systemctl restart nginx
```

**Verify:**
- Visit `http://54.171.56.176` (no :3000)
- You should see the Sparta app

### Step 2: Add it to your script

Once it works manually, add the reverse proxy config to your deployment script using a heredoc:

```bash
#!/bin/bash

# Update and upgrade
sudo apt update -y
sudo apt upgrade -y

# Install Nginx
sudo apt install nginx -y
sudo systemctl enable nginx

# Configure Nginx as a reverse proxy
sudo tee /etc/nginx/sites-available/default > /dev/null << 'EOF'
server {
    listen 80;

    location / {
        proxy_pass http://localhost:3000;
    }
}
EOF

# Restart Nginx to apply config
sudo systemctl restart nginx

# Install Node.js 20.x
sudo bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -"
sudo apt install nodejs -y

# Install pm2
sudo npm install -g pm2

# Clone the app from GitHub
git clone https://github.com/HakimZ78/sparta-test-app.git ~/sparta-test-app

# Install dependencies and start with pm2
cd ~/sparta-test-app/app
sudo npm install
pm2 start app.js --name "sparta-app"
```

### Key difference: `sudo tee` vs `cat >`

- `cat > /etc/nginx/...` — fails because the redirect doesn't have sudo permissions
- `sudo tee /etc/nginx/... > /dev/null` — the `tee` command runs as root so it can write to protected files
- `> /dev/null` suppresses tee's output to the terminal

---

## Summary: The Final Automated Script

Combining all three tasks, your complete deployment script:

```bash
#!/bin/bash

# 1. Update and upgrade
sudo apt update -y
sudo apt upgrade -y

# 2. Install and configure Nginx as reverse proxy
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

# 3. Install Node.js 20.x
sudo bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -"
sudo apt install nodejs -y

# 4. Install pm2 (run app in background)
sudo npm install -g pm2

# 5. Clone app code from GitHub
git clone https://github.com/HakimZ78/sparta-test-app.git ~/sparta-test-app

# 6. Install dependencies and start
cd ~/sparta-test-app/app
sudo npm install
pm2 start app.js --name "sparta-app"
```

**Result:** Visit `http://54.171.56.176` — Sparta app loads, no `:3000`, app runs in background, terminal stays free.

---

## Deployment Workflow Summary

### Option A: With SSH (current approach)

1. **Launch EC2 instance** (ports 22, 80, 3000 open)
2. **scp the script** to the instance:
   ```bash
   scp -i ~/.ssh/se-zaehid-key-pair.pem ~/Documents/MSc-CS/sparta/sparta-notes/scripts/deploy-sparta-app.sh ubuntu@34.241.184.167:~
   ```
3. **SSH in:**
   ```bash
   ssh -i ~/.ssh/se-zaehid-key-pair.pem ubuntu@3.249.80.43
   ```
4. **Make executable and run:**
   ```bash
   chmod +x deploy-sparta-app.sh
   ./deploy-sparta-app.sh
   ```
5. **Visit** `http://34.241.184.167` in browser — done

### Option B: With User Data (zero SSH required)

1. **Launch EC2 instance** — paste script contents into the **User Data** field (remove `sudo` — User Data runs as root)
2. Wait a couple of minutes for the script to finish
3. **Visit** `http://34.241.184.167` in browser — done

Option B is the end goal — **fully automated, no SSH required**.

sudo cat /var/log/cloud-init-output.log | tail -100

cloud-init status
