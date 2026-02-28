# Sparta Global — DevOps Skills Sprint

Documentation and scripts from the 5-day DevOps Skills Sprint, covering cloud deployment on AWS from manual SSH commands through to auto-scaling infrastructure.

## Note on Documentation

These notes were created with AI assistance. I wrote skeleton notes during each session and used AI to structure, expand, with further formatting/editing to create a comprehensive reference material. All technical content was validated through hands-on implementation during the sprint.

As a career changer balancing two professional backgrounds, I used AI the same way I'd use any tool in a DevOps workflow — to automate the repetitive parts (formatting, structure) so I could maximise on understanding the concepts and doing the hands-on work.
---

## What was built

A two-tier Node.js + MongoDB application deployed on AWS EC2, progressively automated over 5 days:

```
Day 1: Manual       → SSH in, type every command
Day 2: Scripted     → Bash scripts, reverse proxy, pm2
Day 3: Two-tier     → Separate DB instance, environment variables
Day 4: AMIs + User Data → Pre-baked images, zero SSH deployment
Day 5: ASG + ALB    → Self-healing, auto-scaling, load-balanced
```

---

## Repository Structure

```
sparta/
├── README.md
├── deployment-workflow.md          # End-to-end deployment reference
├── devops-reference-sheet.md       # Linux, Bash, AWS quick reference
│
├── sparta-notes/
│   ├── day-1/                      # Cloud intro, EC2, SSH, Nginx
│   ├── day-2/                      # Networking, app deployment, scripts, DevOps
│   ├── day-3/                      # MongoDB, two-tier architecture, sed, env vars
│   ├── day-4/                      # AMIs, User Data automation, CloudWatch
│   ├── day-5/                      # Auto Scaling Groups, Load Balancers
│   ├── Take-Home-Tasks/            # Optional tasks: CI/CD, Docker, full SDLC
│   ├── scripts/                    # All deployment and User Data scripts
│   └── images/                     # Screenshots
│
└── sparta_app/                     # The application code
```

---

## Daily Breakdown

| Day | Topics | Key Skills |
|---|---|---|
| **1** | Cloud computing, EC2, SSH key pairs, Nginx | Launched first instance, deployed a web server |
| **2** | NACLs, SCP, bash scripting, reverse proxy, pm2 | Automated deployment with a script |
| **3** | MongoDB, two-tier architecture, sed, DB_HOST | Connected app to database on separate instance |
| **4** | AMIs, User Data, CloudWatch alarms, SNS | Zero-SSH deployment, monitoring and alerting |
| **5** | Auto Scaling Groups, Application Load Balancer | Self-healing, multi-AZ, auto-scaling infrastructure |

---

## Scripts

| Script | Purpose |
|---|---|
| `deploy-sparta-app.sh` | Full app deployment: Nginx, Node.js, pm2, reverse proxy, git clone |
| `deploy-mongo-db.sh` | MongoDB 7.0 install, bindIp config, systemctl enable |
| `user-data-paste-app.sh` | User Data for app AMI (sets DB_HOST, seeds, starts pm2) |
| `user-data-paste-first-db.sh` | User Data for DB AMI (ensures mongod is running) |
| `nginx.sh` | Basic Nginx provisioning script |

---

## Architecture

```
                         ┌─────── Instance 1 (AZ-1a) ─────────┐
                         │  Nginx → Node.js (:3000) → pm2      │
User ──► ALB (port 80) ──┤                                      ├──► MongoDB Instance
                         │  Nginx → Node.js (:3000) → pm2      │    (port 27017)
                         └─────── Instance 2 (AZ-1b) ─────────┘

                         Auto Scaling Group: min 2, max 3, CPU target 50%
```

---

