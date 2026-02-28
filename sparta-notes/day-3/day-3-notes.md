# Day 3 - MongoDB, Two-Tier Architecture & Scripting

---

## Architecture Overview

### Monolith vs Two-Tier (what we're building)

**Monolith** — everything runs on one server (app, database, web server). Simple but doesn't scale.

**Two-Tier** (our setup) — separate instances for the app and database:

```
                    ┌─────────────────────┐
                    │   App Instance       │
User ──► port 80 ──►  Nginx (reverse proxy)│
                    │  Node.js app (:3000) │
                    │  DB_HOST env var ────────► port 27017 ──► DB Instance
                    └─────────────────────┘                    │  MongoDB
                                                               └──────────┘
```

**Benefits of two-tier:**
- **Separation of concerns** — app and database managed independently
- **Security** — database not exposed to the public internet
- **Scalability** — scale the app and database separately
- **Maintenance** — update one without affecting the other

---

## Security Groups Needed

### App Instance SG (existing: `se-zaehid-basic-sg`)

| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 22 | TCP | Your IP | SSH |
| 80 | TCP | 0.0.0.0/0 | HTTP (Nginx) |
| 3000 | TCP | 0.0.0.0/0 | App direct access (testing) |

### DB Instance SG (new: `se-zaehid-db-sg`)

| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 22 | TCP | Your IP | SSH |
| 27017 | TCP | App SG / App private IP | MongoDB — only the app instance should access this |

**Important**: Port 27017 should NOT be open to `0.0.0.0/0` — only the app instance needs access.

---

## Task 1: Manual MongoDB Deployment

### Step 1: Launch a DB EC2 instance
- AMI: Ubuntu 24.04
- Instance type: t3.micro
- Key pair: `se-zaehid-key-pair`
- Security Group: port 22 (SSH) + port 27017 (MongoDB, from app IP only)

### Step 2: SSH into the DB instance
```bash
ssh -i ~/.ssh/se-zaehid-key-pair.pem ubuntu@<DB-PUBLIC-IP>
```

### Step 3: Install MongoDB 7.x

```bash
# Update and upgrade
sudo apt update -y
sudo apt upgrade -y

# Install dependencies (gnupg for key verification, curl for downloading)
sudo apt install gnupg curl -y

# Import MongoDB GPG key — verifies packages are authentic
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

# Add MongoDB 7.0 repository to apt sources
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Update apt to pick up the new repo
sudo apt update -y

# Install specific MongoDB 7.0.6 packages
sudo apt install -y mongodb-org=7.0.6 mongodb-org-database=7.0.6 mongodb-org-server=7.0.6 mongodb-mongosh=2.1.5 mongodb-org-mongos=7.0.6 mongodb-org-tools=7.0.6

# Start and enable MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod

# Verify it's running
sudo systemctl status mongod
```

### Step 4: Change MongoDB configuration — bindIP

By default MongoDB only listens on `127.0.0.1` (localhost). We need it to accept connections from the app instance.

```bash
sudo nano /etc/mongod.conf
```

Find the `net:` section and change `bindIp`:
```yaml
net:
  port: 27017
  bindIp: 0.0.0.0
```

- `127.0.0.1` = only local connections (default)
- `0.0.0.0` = accept connections from any IP
- **Not for production** — in production you'd bind to the specific private IP

Restart MongoDB to apply:
```bash
sudo systemctl restart mongod
```

### Step 5: Set the DB_HOST environment variable on the App instance

SSH into your **app instance** and set the variable:

```bash
# Replace <DB-PRIVATE-IP> with the DB instance's private IP (e.g. 172.31.x.x)
export DB_HOST=mongodb://<DB-PRIVATE-IP>:27017/posts
```

- Use the **private IP** (not public) — both instances are in the same VPC
- `/posts` is the database name the app expects
- `export` makes it available to child processes (like node)

### Step 6: Seed the database and start the app

```bash
cd ~/sparta-test-app/app

# Seed the database with test data
node seeds/seed.js

# Start the app with pm2
pm2 kill
pm2 start app.js --name "sparta-app"
```

### Step 7: Verify

- Visit `http://<APP-PUBLIC-IP>/posts` in your browser
- You should see a page with blog post data from MongoDB

---

## Task 2 (Optional): Redo and Document DB Deployment

Same as Task 1 but from scratch — terminate both instances and start fresh. Document each step with screenshots and explanations. This is for your own reference and learning.

---

## Task 3: Write a Script to Deploy MongoDB

### V1 — Install MongoDB only (manual config still needed)

`deploy-mongo-db.sh`:

```bash
#!/bin/bash

# Update and upgrade
sudo apt update -y
sudo apt upgrade -y

# Install dependencies
sudo apt install gnupg curl -y

# Import MongoDB GPG key
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

# Add MongoDB repository
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Update apt with new repo
sudo apt update -y

# Install MongoDB 7.0.6
sudo apt install -y mongodb-org=7.0.6 mongodb-org-database=7.0.6 mongodb-org-server=7.0.6 mongodb-mongosh=2.1.5 mongodb-org-mongos=7.0.6 mongodb-org-tools=7.0.6

# Start and enable MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod
```

After running this, you'd still need to manually:
1. Edit `/etc/mongod.conf` to change `bindIp` to `0.0.0.0`
2. Restart MongoDB

### V2 — Add these lines to the end of V1

```bash
# Change bindIp from 127.0.0.1 to 0.0.0.0 using sed
sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

# Start and enable MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod
```

#### How the `sed` command works

| Part | Meaning |
|---|---|
| `sed` | Stream editor — edits text in files |
| `-i` | In-place — edit the file directly (not just print output) |
| `s/old/new/` | Substitute — replace `old` with `new` |
| `bindIp: 127.0.0.1` | The text to find |
| `bindIp: 0.0.0.0` | The replacement text |
| `/etc/mongod.conf` | The file to edit |

---

## Task 4: What to Add to Your Existing App Script (`deploy-sparta-app.sh`)

Your script already handles: update, upgrade, Nginx reverse proxy (via `tee`), Node.js, pm2, git clone, npm install, and pm2 start.

To connect to the database, add these lines **before** `pm2 start`:

```bash
# Set DB_HOST environment variable (run on the APP instance, use the DB instance's PRIVATE IP)
export DB_HOST=mongodb://<DB-PRIVATE-IP>:27017/posts

# Seed the database with test data
node seeds/seed.js
```

### Why DB_HOST can't be fully automated (yet)

The `DB_HOST` line goes in the **app script**, not the mongo script. But you can't fully automate it because the **DB private IP changes** every time you launch a new DB instance. You'd have to:

1. Launch the DB instance
2. Note the private IP from AWS Console
3. Manually update the IP in the script before running it

**Future ways to truly automate it:**
- **AWS CLI** — query the DB instance's private IP programmatically in the script:
  ```bash
  DB_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=se-zaehid-db" --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
  export DB_HOST=mongodb://$DB_IP:27017/posts
  ```
- **Terraform** — outputs the DB private IP and passes it to the app instance automatically
- **Elastic IP** — assign a fixed IP so it never changes

For now, manually updating the IP each time is the expected approach.

---

### `sed` vs `tee` for Nginx config

Both approaches work for configuring the reverse proxy:

| | `sed` (Task 4 approach) | `tee` with heredoc (Day 2 approach) |
|---|---|---|
| What it does | Edits one line in the existing config | Replaces the entire config file |
| Precision | Surgical — changes only what you target | Blunt — overwrites everything |
| Risk | May break if line numbers change | Always produces a known config |
| Use case | When you want to keep the rest of the default config | When you want full control |

The `sed` approach targets line 51 specifically:
```bash
sudo sed -i '51s/.*/\t\tproxy_pass http:\/\/127.0.0.1:3000;/' /etc/nginx/sites-available/default
```
- `51s` = on line 51, substitute
- `.*` = match the entire line
- `\t\t` = two tabs for indentation
- `\/` = escaped forward slashes (because `/` is the sed delimiter)

---

## Task 5 (Super Optional Extras)

### Making DB_HOST persistent across sessions

Run these on the **app instance** after SSH-ing in. Use the **DB instance's private IP** (e.g. `172.31.x.x`). You only need to do this once.

`export DB_HOST=...` only lasts for the current session. If you disconnect and SSH back in, it's gone. The options below make it survive across sessions.

**Option 1: Add to `~/.bashrc`**
```bash
echo 'export DB_HOST=mongodb://<DB-PRIVATE-IP>:27017/posts' >> ~/.bashrc
source ~/.bashrc
```
- `~/.bashrc` runs every time you open a new bash session
- `source` reloads it immediately

**Option 2: Add to `/etc/environment`** (system-wide)
```bash
echo 'DB_HOST=mongodb://<DB-PRIVATE-IP>:27017/posts' | sudo tee -a /etc/environment
```
- Available to all users
- No `export` keyword needed in this file

**Option 3: Use a `.env` file** (app-level)
```bash
echo 'DB_HOST=mongodb://<DB-PRIVATE-IP>:27017/posts' > ~/sparta-test-app/app/.env
```
- Requires the app to load `.env` files (e.g. with the `dotenv` package)

### Reverse Proxies — Research Notes

#### What is a proxy server?
- Sits **between the client and the internet**
- Client sends requests to the proxy, proxy forwards them to the target server
- Hides the client's identity from the server
- Use cases: caching, filtering, anonymity

```
Client → Proxy Server → Internet → Target Server
```

#### What is a reverse proxy?
- Sits **between the internet and your backend servers**
- Client thinks it's talking to the reverse proxy, but it's actually forwarding to backend services
- Hides the backend servers from the client

```
Client → Internet → Reverse Proxy (Nginx) → Backend Server (Node.js app)
```

#### Benefits of a reverse proxy
- **Security** — backend servers not directly exposed to the internet
- **Load balancing** — distribute traffic across multiple backend servers
- **SSL termination** — handle HTTPS at the proxy level, backend stays HTTP
- **Caching** — serve static content without hitting the backend
- **Single entry point** — one public IP, many services behind it

#### How we set one up (our Nginx config)

```nginx
server {
    listen 80;

    location / {
        proxy_pass http://localhost:3000;
    }
}
```

This tells Nginx: "Listen on port 80. When a request comes in, forward it to the Node.js app on port 3000. Send the response back to the client."

---

## Commands Reference

| Command | What it does |
|---|---|
| `sudo sed -i 's/old/new/' file` | Find and replace text in a file |
| `export VAR=value` | Set an environment variable for the current session |
| `echo 'export VAR=value' >> ~/.bashrc` | Make an env var persistent |
| `node seeds/seed.js` | Seed the database with test data |
| `pm2 kill` | Kill all pm2 processes |
| `pm2 start app.js --name "name"` | Start an app with pm2 in the background |
| `sudo systemctl status mongod` | Check if MongoDB is running |
| `mongosh` | Open MongoDB shell (to verify connection) |

---

## Deployment Order (Two-Tier)

Always deploy in this order:

1. **DB instance first** — MongoDB needs to be running before the app tries to connect
2. **App instance second** — set `DB_HOST`, seed the database, start the app

```
1. Launch DB instance → run mongo script → MongoDB listening on 0.0.0.0:27017
2. Launch App instance → run app script (with DB_HOST set) → seed DB → start app
3. Visit http://<APP-IP>/posts → data from MongoDB displayed
```

---

## Tomorrow

Review scripts to get everyone aligned, then look at **custom AMIs** — pre-baked images so you don't need to run scripts at all.
