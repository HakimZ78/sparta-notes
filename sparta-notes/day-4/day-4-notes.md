# Day 4 - AMIs, User Data Automation & CloudWatch

---

## Task 1: Deploy Sparta App + DB Together (/posts working)

Already done — see `deployment-workflow.md` for the full process. Confirm by visiting:
- `http://<APP-PUBLIC-IP>` — Sparta app home
- `http://<APP-PUBLIC-IP>/posts` — posts from MongoDB

---

## Task 2: Create an App AMI (Image)

An AMI is a **snapshot** of your configured instance. Launch new instances from it with everything pre-installed — no scripts needed.

### Why?
- AMIs are faster than running scripts — the instance launches already configured
- Combined with User Data, you get a fully automated deployment
- Like a "golden image" — consistent, repeatable

### Steps to create an App AMI

1. **Stop the app instance first** (don't terminate)
   - AWS Console → EC2 → select instance → **Instance state** → **Stop instance**
   - Stopping ensures a clean, consistent image

2. **Create the image**
   - Select the stopped instance → **Actions** → **Image and templates** → **Create image**
   - Name: `se-zaehid-app-ami`
   - Description: "Ubuntu 24.04 with Nginx, Node.js 20, pm2, Sparta app"
   - Wait for the AMI status to show `available` (takes a few minutes)

3. **Launch a new instance from the AMI**
   - EC2 → **Launch Instance**
   - Under AMI: **My AMIs** → select `se-zaehid-app-ami`
   - Same config: t3.micro, your key pair, app SG (ports 22, 80, 3000)

4. **SSH in and start the app**
   ```bash
   ssh -i ~/.ssh/se-zaehid-key-pair.pem ubuntu@<NEW-PUBLIC-IP>

   export DB_HOST=mongodb://<DB-PRIVATE-IP>:27017/posts
   cd ~/sparta-test-app/app
   node seeds/seed.js
   pm2 start app.js --name "sparta-app"
   ```

5. **Verify** — visit `http://<NEW-PUBLIC-IP>/posts`

6. **Delete the original instance** once the AMI-based one works

### DB AMI — same process
- Stop the DB instance
- Create image: `se-zaehid-db-ami`
- Launch from it — MongoDB is already installed and configured
- MongoDB should start automatically if you used `systemctl enable mongod` in your script

---

## Task 3 (Optional): Redo and Document Image Deployment

Terminate everything and start fresh from your AMIs. Document with screenshots.

---

## Task 4: Automate with User Data

### Goal 1: App homepage works "out of the box" (no SSH)

Use your **App AMI** + **User Data** to start the app automatically on launch.

Since the AMI already has everything installed, the User Data script only needs to **start** things:

```bash
#!/bin/bash

cd /home/ubuntu/sparta-test-app/app
pm2 start app.js --name "sparta-app"
```

- Paste this into **Advanced Details → User Data** when launching from your App AMI
- User Data runs as root, so paths must be absolute (`/home/ubuntu/...` not `~/...`)
- Visit `http://<PUBLIC-IP>` — should work without SSH

### Goal 2: /posts also works "out of the box"

Extend the User Data to connect to the DB and seed:

```bash
#!/bin/bash

export DB_HOST=mongodb://<DB-PRIVATE-IP>:27017/posts
cd /home/ubuntu/sparta-test-app/app
node seeds/seed.js
pm2 start app.js --name "sparta-app"
```

- You still need to know the DB private IP in advance
- Launch the DB instance first (from DB AMI), note the private IP, then use it in the app's User Data

### User Data vs regular scripts — key differences

| | Regular script (`deploy-sparta-app.sh`) | User Data |
|---|---|---|
| Runs as | `ubuntu` user (needs `sudo`) | `root` user (no `sudo` needed) |
| Paths | `~/` = `/home/ubuntu/` | `~/` = `/root/` — use absolute paths |
| When it runs | When you execute it manually | Automatically on first boot |
| Interactive prompts | Can handle them | **Cannot** — add `DEBIAN_FRONTEND=noninteractive` |
| Debugging | See output in terminal | Check `sudo cat /var/log/cloud-init-output.log` |

### User Data scripts saved at
- `scripts/user-data-app.sh` — User Data for app AMI (sets DB_HOST, seeds, starts pm2)
- `scripts/user-data-db.sh` — User Data for DB AMI (ensures MongoDB is running)

### User Data + AMI Workflow (zero SSH deployment)

1. **Launch DB instance from DB AMI**
   - AMI: `se-zaehid-db-ami`
   - SG: ports 22 + 27017
   - User Data: paste contents of `scripts/user-data-db.sh`
   - Wait for it to start, note the **private IP**

2. **Update `scripts/user-data-app.sh`**
   - Replace `<DB-PRIVATE-IP>` with the actual DB private IP

3. **Launch App instance from App AMI**
   - AMI: `se-zaehid-app-ami`
   - SG: ports 22 + 80 + 3000
   - User Data: paste contents of `scripts/user-data-app.sh` (with updated IP)

4. **Wait 1-2 minutes, then visit:**
   - `http://<APP-PUBLIC-IP>` — Sparta app
   - `http://<APP-PUBLIC-IP>/posts` — posts from MongoDB

5. **If something goes wrong, debug with:**
   ```bash
   ssh -i ~/.ssh/se-zaehid-key-pair.pem ubuntu@<APP-PUBLIC-IP>
   sudo cat /var/log/cloud-init-output.log | tail -50
   ```

---

## Task 5 (Optional): AWS CloudWatch Monitoring

### What is CloudWatch?
- AWS's built-in monitoring and observability service
- Collects metrics, logs, and alarms for your AWS resources
- Free tier includes basic monitoring (5-minute intervals)

### Enable detailed monitoring
1. EC2 Console → select instance → **Actions** → **Monitor and troubleshoot** → **Manage detailed monitoring**
2. Enable it — switches from 5-minute to **1-minute** intervals
3. Note: detailed monitoring has a small cost

### Create a dashboard
1. CloudWatch Console → **Dashboards** → **Create dashboard**
2. Name: `se-zaehid-dashboard`
3. Add widgets:
   - **Line chart**: EC2 → Per-Instance Metrics → CPUUtilization
   - **Number**: NetworkIn / NetworkOut
   - **Line chart**: DiskReadOps / DiskWriteOps

### Set up a CPU alarm
1. CloudWatch → **Alarms** → **Create alarm**
2. Select metric: EC2 → Per-Instance Metrics → **CPUUtilization**
3. Condition: **Greater than 50%**
4. Period: 1 minute

### Trigger the alarm (stress test)
SSH into your instance and run:
```bash
# Install stress tool
sudo apt install stress -y

# Stress CPU for 5 minutes (adjust as needed)
stress --cpu 4 --timeout 300
```

Watch the alarm go from `OK` → `In alarm` in the CloudWatch console.

### Add email notification
1. When creating the alarm, under **Notification**:
   - Create a new **SNS topic**: `se-zaehid-cpu-alarm`
   - Add your email address
2. Check your email and **confirm the subscription**
3. When the alarm triggers, you'll receive an email

### Clean up before logging off
- **Delete** your CloudWatch dashboard
- **Terminate** all running instances
- Check for any lingering resources

---

## Summary: The Automation Progression

```
Day 1: Manual — SSH in, type every command
Day 2: Scripted — bash scripts, scp to instance, run manually
Day 3: Two-tier — separate DB + app scripts
Day 4: AMIs + User Data — pre-baked images, zero SSH deployment
```

Each step reduces manual work. The end goal: **launch an instance and everything works automatically.**
