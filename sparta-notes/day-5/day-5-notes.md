# Day 5 - Auto Scaling, Load Balancing & Next Steps

---

## High Availability — The Problem

A single EC2 instance is a **single point of failure**:
- If it crashes, the app goes down
- If traffic spikes, one instance can't handle the load
- If the AZ has an outage, everything in it is affected

The solution: **Auto Scaling Groups + Load Balancers** — run multiple instances across multiple Availability Zones and distribute traffic between them.

---

## Scaling: Horizontal vs Vertical

### Vertical Scaling (scale up)
- Make the existing instance **bigger** — more CPU, more RAM
- e.g. upgrade from `t3.micro` to `t3.large`
- **Downtime** required to resize
- Has a ceiling — there's a largest instance type
- Use case: databases, ML workloads, single-threaded applications

### Horizontal Scaling (scale out)
- Add **more instances** of the same size
- e.g. go from 1x `t3.micro` to 3x `t3.micro`
- **No downtime** — new instances are added alongside existing ones
- Theoretically unlimited scaling
- Use case: web servers, APIs, stateless applications — **this is what ASGs do**

```
Vertical:                     Horizontal:
┌─────────┐                   ┌───┐ ┌───┐ ┌───┐
│         │                   │   │ │   │ │   │
│  BIGGER │                   │ S │ │ S │ │ S │
│ INSTANCE│                   │ M │ │ M │ │ M │
│         │                   │ A │ │ A │ │ A │
│         │                   │ L │ │ L │ │ L │
│         │                   │ L │ │ L │ │ L │
└─────────┘                   └───┘ └───┘ └───┘
```

---

## Key Components

### Launch Template

A **blueprint** for the instances the ASG will create. Defines:
- AMI (which image to use)
- Instance type (e.g. `t3.micro`)
- Key pair
- Security group
- User Data script (what to run on boot)

You create a Launch Template **before** creating the ASG. If you only have an AMI, create a Launch Template from it first.

### Auto Scaling Group (ASG)

Manages a **group of identical instances** based on rules you define:

| Setting | What it controls |
|---|---|
| Desired capacity | How many instances to run normally (we set **2**) |
| Minimum capacity | Never go below this (we set **2**) |
| Maximum capacity | Never go above this (we set **3**) |

The ASG:
- Launches instances across **multiple Availability Zones** (eu-west-1a, 1b, 1c) for resilience
- **Self-heals** — if an instance is terminated or fails a health check, the ASG replaces it automatically
- **Scales out** when demand increases (based on scaling policy)
- **Scales in** when demand decreases

### Scaling Policy

Rules that tell the ASG **when** to add or remove instances:

- We used: **Target tracking** — keep average CPU utilisation at **50%**
- If CPU goes above 50%, the ASG adds instances (up to max 3)
- If CPU drops, the ASG removes instances (down to min 2)

This ties directly into **CloudWatch** (Day 4) — CloudWatch monitors the metric, the ASG acts on it.

```
CloudWatch (monitoring) ──► CPU > 50% alarm ──► ASG (action) ──► Launch new instance
```

### Application Load Balancer (ALB)

Distributes incoming traffic across healthy instances:

```
                         ┌─── Instance 1 (eu-west-1a)
User ──► Load Balancer ──┤
                         ├─── Instance 2 (eu-west-1b)
                         │
                         └─── Instance 3 (eu-west-1c) [if scaled out]
```

| Component | Purpose |
|---|---|
| Load Balancer | Public-facing entry point — users hit the LB's DNS name, not individual instance IPs |
| Target Group | The pool of instances the LB sends traffic to |
| Health Checks | LB checks each instance is healthy — unhealthy targets stop receiving traffic |
| Listener | Listens on port 80 (HTTP) and forwards to the target group |

**Key point**: Users access the app via the **Load Balancer DNS name**, not individual instance IPs. The LB handles routing.

### How it all fits together

```
                    Auto Scaling Group
                    ┌─────────────────────────────────────────┐
                    │                                         │
                    │   AZ-1a         AZ-1b         AZ-1c    │
User ──► ALB ──────►│  ┌─────┐     ┌─────┐     ┌─────┐     │
   (DNS name)       │  │ EC2 │     │ EC2 │     │ EC2 │     │
                    │  │  1  │     │  2  │     │  3  │     │
                    │  └─────┘     └─────┘     └─────┘     │
                    │                                         │
                    │  Scaling Policy: CPU > 50% → scale out  │
                    │  Min: 2 | Desired: 2 | Max: 3           │
                    └─────────────────────────────────────────┘
                                       │
                    Launch Template (AMI + config + User Data)
```

---

## Task: Create an ASG with a Load Balancer

See `instructions.md` for the full step-by-step AWS Console walkthrough.

### Summary of what we configured

1. **Launch Template** — created from our App AMI (everything pre-installed)
2. **ASG** — name: `se-zaehid-app-asg`
   - 3 AZs selected (1a, 1b, 1c)
   - Desired: 2, Min: 2, Max: 3
   - Scaling policy: target CPU at 50%
3. **Application Load Balancer** — name: `se-zaehid-app-asg-lb`
   - Internet-facing, listening on port 80 (HTTP)
   - Target group: `se-zaehid-app-asg-lb-tg`
   - ELB health checks enabled (grace period: 300s)
4. **Tag** — `Name: se-zaehid-app-asg` (so instances get named)

### Testing self-healing

- Terminated one of the ASG's instances
- The page temporarily went down while the LB detected the unhealthy target
- The ASG automatically launched a replacement instance
- App came back online — **self-healing in action**

### Why scripts when we have AMIs and ASGs?

- **Portability** — scripts work on any cloud, not just AWS
- **Backup** — if AMIs are lost or corrupted, scripts can rebuild from scratch
- **Customisation** — easier to modify a script than create a new AMI
- **Version control** — scripts can be tracked in git, AMIs can't

---

## Clean Up Order (Important!)

Resources must be deleted in this order to avoid orphaned resources:

```
1. Delete Load Balancer
2. Delete Target Group
3. Delete ASG          ← this terminates the instances
4. Double-check instances are terminated
```

If you delete the ASG first without the LB, the LB will keep trying to route to non-existent targets. If you just terminate instances without deleting the ASG, it will **recreate them**.

---

## Where Next? — Career & Learning Path

### Core advice from Luke (educator, GitHub: LSF970)

- **Lock down the core concepts** — understand what you've done this week deeply before moving on
- **Understand business value** — demonstrate to employers how DevOps practices solve business problems (uptime, cost reduction, faster releases)
- **Git vs GitHub** — know the difference. Git = source code management (SCM) tool. GitHub = a platform that hosts Git repositories

### Future Sprints (upcoming training)

| Topic | What it covers |
|---|---|
| Deployment in VPC | Custom networking, public/private subnets, NAT gateways |
| CI/CD Pipelines | GitHub Actions, Jenkins — automate build, test, deploy |
| Docker + Kubernetes | Containerisation and orchestration |
| IaC with Terraform & Ansible | Infrastructure as Code — define infrastructure in config files |

### Scripting beyond Bash

| Language | Strengths |
|---|---|
| **Python** | More powerful than Bash for complex logic, APIs, data processing |
| **Go** | Fast, compiled, used in DevOps tools (Docker, Kubernetes, Terraform are written in Go) |
| **Groovy** | Used in Jenkins pipelines |
| **Rust** | Systems programming, performance-critical tools |

**Automate anything you do regularly** — if you do it more than twice, script it.

### Project idea: Advanced Monitoring

Build a monitoring stack with:
- **Apache Kafka** — data ingestion / streaming
- **Splunk** — log analysis and predictive analytics
- Related to **SIEM** (Security Information and Event Management) and **SOC** (Security Operations Centre) roles

### Target Job Titles

Research these roles — add "Junior" to most:

| Role | Focus |
|---|---|
| **DevOps Engineer** | CI/CD, automation, infrastructure |
| **Cloud Engineer** | AWS/Azure/GCP architecture and services |
| **Site Reliability Engineer (SRE)** | Uptime, reliability, incident response |
| **Platform Engineer** | Internal developer platforms and tooling |
| **DataOps Engineer** | Data pipeline automation |
| **Support Engineer (2nd/3rd line)** | Troubleshooting, escalation, systems |
| **Automation Engineer** | Testing and infrastructure automation |
| **Linux Systems Administrator** | Server management, configuration |
| **Build Engineer** | Build systems, CI/CD pipelines |
| **Release Manager** | Coordinating deployments and releases |

### Action item

Contact Rebecca at Sparta about getting access to videos/AWS platform for the next sprint.

---

## Week Summary: The Automation Progression

```
Day 1: Manual         — SSH in, type every command by hand
Day 2: Scripted       — Bash scripts, scp to instance, run manually
Day 3: Two-tier       — Separate DB + app scripts, MongoDB on its own instance
Day 4: AMIs + User Data — Pre-baked images, zero SSH deployment
Day 5: ASG + ALB      — Self-healing, auto-scaling, load-balanced, multi-AZ
```

Each day reduced manual work. The end goal: **infrastructure that manages itself**.
