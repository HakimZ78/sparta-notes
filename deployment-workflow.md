# Two-Tier Deployment Workflow

---

## Restart Workflow (Instances Already Exist)

Use this when you've **stopped** your instances (not terminated). Everything is still installed — you just need new public IPs and to restart the services.

### Step 1: Start both instances
- AWS Console → EC2 → Instances → select both → **Instance state** → **Start instance**

### Step 2: Get the new public IPs
- Click each instance → note the new **Public IPv4 address**
- The **private IPs stay the same**

### Step 3: SSH into DB instance and verify MongoDB is running
```bash
ssh -i ~/.ssh/se-zaehid-key-pair.pem ubuntu@<NEW-DB-PUBLIC-IP>
sudo systemctl status mongod
```
If it's not running: `sudo systemctl start mongod`

### Step 4: SSH into App instance and restart the app
```bash
ssh -i ~/.ssh/se-zaehid-key-pair.pem ubuntu@<NEW-APP-PUBLIC-IP>

# Set DB_HOST (private IP hasn't changed)
export DB_HOST=mongodb://<DB-PRIVATE-IP>:27017/posts

# Restart the app
cd ~/sparta-test-app/app
pm2 start app.js --name "sparta-app"
```

### Step 5: Verify
- `http://<NEW-APP-PUBLIC-IP>` — Sparta app
- `http://<NEW-APP-PUBLIC-IP>/posts` — data from MongoDB

**No scripts to copy, no installs needed.** Just new public IPs and restart services.

---

## Full Workflow (Fresh Instances from Scratch)

Complete step-by-step guide for deploying the Sparta app with MongoDB on brand new instances.

---

## Prerequisites

- AWS account with EC2 access
- Key pair: `se-zaehid-key-pair` (stored at `~/.ssh/se-zaehid-key-pair.pem`)
- Two Security Groups:
  - **App SG** (`se-zaehid-basic-sg`): ports 22, 80, 3000
  - **DB SG** (`se-zaehid-db-sg`): ports 22, 27017 (from app SG only)
- App code on GitHub: `https://github.com/HakimZ78/sparta-test-app.git`
- Scripts ready locally:
  - `~/Documents/MSc-CS/sparta/sparta-notes/scripts/deploy-mongo-db.sh`
  - `~/Documents/MSc-CS/sparta/sparta-notes/scripts/deploy-sparta-app.sh`

---

## Step 1: Launch DB Instance

1. **EC2 Console** → Launch Instance
   - Name: `se-zaehid-db`
   - AMI: Ubuntu 24.04
   - Instance type: t3.micro
   - Key pair: `se-zaehid-key-pair`
   - Security Group: `se-zaehid-db-sg` (ports 22 + 27017)

2. **Copy the DB script to the instance:**
   ```bash
   scp -i ~/.ssh/se-zaehid-key-pair.pem ~/Documents/MSc-CS/sparta/sparta-notes/scripts/deploy-mongo-db.sh ubuntu@<DB-PUBLIC-IP>:~
   ```

3. **SSH in and run:**
   ```bash
   ssh -i ~/.ssh/se-zaehid-key-pair.pem ubuntu@<DB-PUBLIC-IP>
   chmod +x deploy-mongo-db.sh
   ./deploy-mongo-db.sh
   ```

4. **Verify MongoDB is running:**
   ```bash
   sudo systemctl status mongod
   ```
   Look for "active (running)". Press `q` to exit.

5. **Note the private IP** — AWS Console → click instance → **Private IPv4 address** (e.g. `172.31.x.x`)

---

## Step 2: Launch App Instance

1. **EC2 Console** → Launch Instance
   - Name: `se-zaehid-app`
   - AMI: Ubuntu 24.04
   - Instance type: t3.micro
   - Key pair: `se-zaehid-key-pair`
   - Security Group: `se-zaehid-basic-sg` (ports 22 + 80 + 3000)

2. **Copy the app script to the instance:**
   ```bash
   scp -i ~/.ssh/se-zaehid-key-pair.pem ~/Documents/MSc-CS/sparta/sparta-notes/scripts/deploy-sparta-app.sh ubuntu@<APP-PUBLIC-IP>:~
   ```

3. **SSH in and run:**
   ```bash
   ssh -i ~/.ssh/se-zaehid-key-pair.pem ubuntu@<APP-PUBLIC-IP>
   chmod +x deploy-sparta-app.sh
   ./deploy-sparta-app.sh
   ```

---

## Step 3: Connect App to Database

Still on the app instance:

```bash
# Set the DB_HOST variable (replace <DB-PRIVATE-IP> with actual private IP from Step 1)
export DB_HOST=mongodb://<DB-PRIVATE-IP>:27017/posts
# printenv DB_HOST (to check set)
# Seed the database with test data
cd ~/sparta-test-app/app
node seeds/seed.js

# Restart the app so it picks up DB_HOST
pm2 kill
pm2 start app.js --name "sparta-app"
```

---

## Step 4: Verify

| URL | What you should see |
|---|---|
| `http://<APP-PUBLIC-IP>` | Sparta app home page (via Nginx reverse proxy) |
| `http://<APP-PUBLIC-IP>/posts` | Blog posts pulled from MongoDB |

---

## Quick Reference

### SSH commands
```bash
# DB instance
ssh -i ~/.ssh/se-zaehid-key-pair.pem ubuntu@<DB-PUBLIC-IP>

# App instance
ssh -i ~/.ssh/se-zaehid-key-pair.pem ubuntu@<APP-PUBLIC-IP>
```

### Useful checks
```bash
# On DB instance
sudo systemctl status mongod        # is MongoDB running?

# On App instance
pm2 status                           # is the app running?
pm2 logs sparta-app                  # app logs (check for errors)
echo $DB_HOST                        # is the env var set?
sudo nginx -t                        # is Nginx config valid?
sudo systemctl status nginx          # is Nginx running?
```

### Troubleshooting

| Problem | Check |
|---|---|
| App page doesn't load | Is Nginx running? `sudo systemctl status nginx` |
| App loads but `/posts` shows no data | Is `DB_HOST` set? `echo $DB_HOST` |
| `/posts` errors | Is MongoDB running on DB instance? Can app reach it? Check SG port 27017 |
| Connection refused on :3000 | Is the app running? `pm2 status` |
| `npm: command not found` | Node.js didn't install — rerun the NodeSource curl command |

---

## End of Day

**Terminate both instances by 18:00.** IPs will change on next launch — that's expected. The scripts handle all the installation; you only need to update IPs.
