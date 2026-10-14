# AWS Cloud Networking — 5-Day Sprint Course
### Sparta Education | Detailed Learning Reference

---

## How to Use This Document

This reference covers every topic in the Sparta Education 5-day sprint. Each section explains the concept, why it matters, and includes practical AWS implementation notes. All hands-on exercises use the **AWS Management Console** and **AWS CLI**.

---

## Table of Contents

1. [Virtual Private Clouds (VPCs)](#1-virtual-private-clouds-vpcs)
2. [Subnets](#2-subnets)
3. [Autoscaling](#3-autoscaling)
4. [Load Balancing](#4-load-balancing)
5. [Suggested 5-Day Schedule](#5-suggested-5-day-schedule)
6. [AWS CLI Quick Reference](#6-aws-cli-quick-reference)
7. [Key Terminology Glossary](#7-key-terminology-glossary)
8. [OSI Model — Networking Foundation](#8-osi-model--networking-foundation)
9. [DNS & Route 53](#9-dns--route-53)
10. [Common Ports Reference](#10-common-ports-reference)
11. [EC2 Fundamentals for Autoscaling](#11-ec2-fundamentals-for-autoscaling)
12. [CloudFront — CDN Integration](#12-cloudfront--cdn-integration)
13. [Network Troubleshooting Playbook](#13-network-troubleshooting-playbook)
14. [Cost Awareness for Sprint Labs](#14-cost-awareness-for-sprint-labs)

---

## 1. Virtual Private Clouds (VPCs)

### What is a VPC?

A **Virtual Private Cloud (VPC)** is a logically isolated section of the AWS cloud where you launch AWS resources in a virtual network that you define. Think of it as your own private data centre hosted inside AWS — you control the IP address range, routing, and who can access what.

Before VPCs existed, all AWS resources shared a flat network. This was a significant security risk. VPCs solve this by giving each customer (or project) their own isolated network boundary.

### Core Concepts

#### CIDR Blocks
When you create a VPC, you assign it a **CIDR block** (Classless Inter-Domain Routing). This defines the range of private IP addresses available inside your VPC.

- Example: `10.0.0.0/16` — gives you 65,536 IP addresses
- Example: `192.168.0.0/24` — gives you 256 IP addresses
- AWS reserves 5 IP addresses in every CIDR block (first four and last)

**Choosing a CIDR block:** Use RFC 1918 private ranges:
- `10.0.0.0/8`
- `172.16.0.0/12`
- `192.168.0.0/16`

Pick a range large enough for growth but avoid overlapping with other VPCs or on-premises networks you may want to connect to later.

#### Internet Gateway (IGW)
An **Internet Gateway** is a horizontally scaled, redundant, and highly available VPC component that allows communication between your VPC and the internet.

- One IGW per VPC
- Attach it to your VPC to enable internet access
- Without an IGW, resources in your VPC are completely isolated from the internet
- Resources in public subnets also need a public IP or Elastic IP to communicate outbound

#### Route Tables
Route tables contain rules (**routes**) that determine where network traffic is directed.

- Every subnet must be associated with a route table
- The **main route table** is created automatically with the VPC
- Local route (`10.0.0.0/16 → local`) always present — allows internal VPC traffic
- To make a subnet "public", add a route: `0.0.0.0/0 → igw-xxxxxxxx`

#### Security Groups vs Network ACLs

| Feature | Security Group | Network ACL |
|---|---|---|
| Level | Instance (resource) level | Subnet level |
| Stateful? | Yes — return traffic auto-allowed | No — must explicitly allow inbound AND outbound |
| Rules | Allow rules only | Allow and Deny rules |
| Evaluation | All rules evaluated together | Rules evaluated in number order |
| Default | Deny all inbound, allow all outbound | Allow all traffic (default NACL) |

**Security Groups** are your first line of defence around EC2 instances. NACLs are a second layer of defence at the subnet boundary.

#### VPC Peering
VPC peering connects two VPCs privately, routing traffic using private IP addresses. Peered VPCs behave as if they are in the same network.

- Works across accounts and regions
- Non-transitive — A can talk to B, B can talk to C, but A cannot reach C via B (unless explicitly peered)
- No bandwidth bottleneck, no single point of failure

#### VPC Endpoints
Allows private connectivity to AWS services (e.g., S3, DynamoDB) without needing an IGW or NAT Gateway.

- **Gateway Endpoints** — for S3 and DynamoDB (free)
- **Interface Endpoints** — for most other AWS services (uses PrivateLink, charged per hour + data)

### AWS Hands-On: Create a VPC

```bash
# Create a VPC with a /16 CIDR block
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications \
  'ResourceType=vpc,Tags=[{Key=Name,Value=my-sprint-vpc}]'

# Create and attach an Internet Gateway
aws ec2 create-internet-gateway
aws ec2 attach-internet-gateway --vpc-id vpc-xxxxxxxx --internet-gateway-id igw-xxxxxxxx

# View your VPCs
aws ec2 describe-vpcs
```

> **Console Path:** VPC → Your VPCs → Create VPC

### Why This Matters

A VPC is the foundation of everything you build in AWS. Every EC2 instance, RDS database, Lambda function, and EKS cluster lives inside a VPC. Misconfigured VPCs are one of the most common causes of both security breaches and connectivity failures in cloud environments.

---

## 2. Subnets

### What is a Subnet?

A **subnet** (subnetwork) is a range of IP addresses within your VPC. It is always tied to a single **Availability Zone (AZ)**. Subnets let you segment your VPC into logical sections with different access rules and routing policies.

### Public vs Private Subnets

| | Public Subnet | Private Subnet |
|---|---|---|
| Route to internet | Yes — via IGW | No direct route |
| Typical resources | Web servers, load balancers, bastion hosts | App servers, databases, internal services |
| Direct internet access | Yes (with public IP) | No |
| Outbound internet | Via IGW | Via NAT Gateway in a public subnet |

**Best practice:** Never place databases or internal application servers in a public subnet.

### CIDR Allocation for Subnets

You carve subnets out of your VPC CIDR block. Each subnet needs its own non-overlapping CIDR range.

Example — VPC: `10.0.0.0/16`

| Subnet | CIDR | AZ | Type |
|---|---|---|---|
| Public Subnet A | `10.0.1.0/24` | eu-west-1a | Public |
| Public Subnet B | `10.0.2.0/24` | eu-west-1b | Public |
| Private Subnet A | `10.0.10.0/24` | eu-west-1a | Private |
| Private Subnet B | `10.0.11.0/24` | eu-west-1b | Private |
| DB Subnet A | `10.0.20.0/24` | eu-west-1a | Private (DB) |
| DB Subnet B | `10.0.21.0/24` | eu-west-1b | Private (DB) |

Spreading across multiple AZs is essential for **high availability**.

### NAT Gateway

Private subnet resources often need to reach the internet (e.g., to download OS patches), but must not be reachable from the internet. A **NAT Gateway** enables this.

- Placed in a **public subnet**
- Private subnet route table points `0.0.0.0/0` to the NAT Gateway
- NAT Gateway translates private IP → its public Elastic IP for outbound traffic
- Managed service — AWS handles availability and scaling
- **Cost:** Charged per hour + per GB data processed

**NAT Instance** (older approach): an EC2 instance acting as a NAT. Cheaper but requires you to manage it.

### Subnet Route Table Configuration

```
Public Subnet Route Table:
  10.0.0.0/16 → local
  0.0.0.0/0   → igw-xxxxxxxx

Private Subnet Route Table:
  10.0.0.0/16 → local
  0.0.0.0/0   → nat-xxxxxxxx
```

### AWS Hands-On: Create Subnets

```bash
# Create a public subnet in AZ a
aws ec2 create-subnet \
  --vpc-id vpc-xxxxxxxx \
  --cidr-block 10.0.1.0/24 \
  --availability-zone eu-west-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-a}]'

# Enable auto-assign public IPs for public subnet
aws ec2 modify-subnet-attribute \
  --subnet-id subnet-xxxxxxxx \
  --map-public-ip-on-launch

# Create a route table and associate with public subnet
aws ec2 create-route-table --vpc-id vpc-xxxxxxxx
aws ec2 create-route --route-table-id rtb-xxxxxxxx \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id igw-xxxxxxxx
aws ec2 associate-route-table --subnet-id subnet-xxxxxxxx --route-table-id rtb-xxxxxxxx
```

> **Console Path:** VPC → Subnets → Create Subnet

### Multi-Tier Architecture Pattern

A well-designed AWS application typically uses three tiers of subnets:

```
Internet
    │
    ▼
[Public Subnet]       — ALB, Bastion Host, NAT Gateway
    │
    ▼
[Private App Subnet]  — EC2 Auto Scaling Group, ECS Tasks
    │
    ▼
[Private DB Subnet]   — RDS, ElastiCache (DB Subnet Group)
```

---

## 3. Autoscaling

### What is Autoscaling?

**AWS Auto Scaling** automatically adjusts the number of EC2 instances (or other resources) in response to changing demand. It ensures you always have the right amount of capacity — not too little (causing poor performance) and not too much (wasting money).

### Components of EC2 Auto Scaling

#### Launch Template (or Launch Configuration)
Defines the configuration of EC2 instances that the Auto Scaling Group will launch:

- AMI ID (the OS image)
- Instance type (e.g., `t3.micro`)
- Key pair for SSH access
- Security groups
- IAM instance profile
- User data script (bootstrap commands)
- EBS volume configuration

**Launch Templates** are the modern approach and support versioning and mixed instance types. Launch Configurations are legacy and should be avoided for new projects.

#### Auto Scaling Group (ASG)
The ASG is the core resource that manages the fleet of EC2 instances:

- **Minimum capacity** — floor: never go below this number of instances
- **Maximum capacity** — ceiling: never exceed this number
- **Desired capacity** — the target number of instances right now
- Tied to one or more **subnets** (spread across AZs for HA)
- Optionally attached to a **Load Balancer Target Group**

#### Scaling Policies

**1. Target Tracking Scaling (recommended)**
Set a target metric value; AWS automatically adds/removes instances to maintain it.

Examples:
- Keep average CPU utilisation at 50%
- Keep average request count per target at 1000 requests/minute
- Maintain ALBRequestCountPerTarget

**2. Step Scaling**
Define steps: if CPU > 70% add 2 instances; if CPU > 90% add 4 instances. Gives more precise control.

**3. Simple Scaling**
Basic: if alarm triggers, add/remove N instances. Has a cooldown period before next action.

**4. Scheduled Scaling**
Scale at a known time — e.g., scale up every weekday at 08:00, scale down at 20:00. Useful for predictable traffic patterns.

**5. Predictive Scaling**
Uses ML to forecast future demand based on historical patterns and schedules capacity proactively.

### Cooldown Periods and Warm-Up

- **Cooldown period** — after a scaling action, wait N seconds before evaluating another action (prevents thrashing)
- **Instance warm-up** — time for a new instance to come online and start contributing metrics to CloudWatch

### Health Checks

Auto Scaling terminates unhealthy instances and replaces them automatically.

- **EC2 health check** — instance status checks (default)
- **ELB health check** — load balancer health check results (recommended when using a load balancer)

### Lifecycle Hooks

Lifecycle hooks pause instance launch or termination so you can run custom actions:

- On **launch**: install software, pull config from S3, register with monitoring
- On **terminate**: drain connections, send logs to S3, deregister from service discovery

### AWS Hands-On: Create an Auto Scaling Group

```bash
# Create a Launch Template
aws ec2 create-launch-template \
  --launch-template-name my-sprint-lt \
  --version-description "v1" \
  --launch-template-data '{
    "ImageId": "ami-xxxxxxxxxx",
    "InstanceType": "t3.micro",
    "SecurityGroupIds": ["sg-xxxxxxxx"],
    "UserData": "IyEvYmluL2Jhc2gKYXB0IHVwZGF0ZSAteQ=="
  }'

# Create an Auto Scaling Group
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name my-sprint-asg \
  --launch-template LaunchTemplateName=my-sprint-lt,Version='$Latest' \
  --min-size 1 \
  --max-size 4 \
  --desired-capacity 2 \
  --vpc-zone-identifier "subnet-xxxxxxxx,subnet-yyyyyyyy"

# Add a target tracking policy
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name my-sprint-asg \
  --policy-name cpu-target-tracking \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ASGAverageCPUUtilization"
    },
    "TargetValue": 50.0
  }'
```

> **Console Path:** EC2 → Auto Scaling Groups → Create Auto Scaling Group

### Cost Optimisation with Autoscaling

Pair Auto Scaling with:

- **Spot Instances** — up to 90% cheaper than On-Demand; use for stateless, fault-tolerant workloads
- **Mixed instance policies** — combine On-Demand (base capacity) + Spot (scale-out capacity)
- **Instance Refresh** — rolling replacement of instances when the Launch Template changes

---

## 4. Load Balancing

### What is Load Balancing?

A **load balancer** distributes incoming application traffic across multiple targets (typically EC2 instances) to ensure no single instance is overwhelmed. It also removes unhealthy instances from rotation automatically.

Without a load balancer, you'd need to either send all traffic to one server (single point of failure) or manually manage traffic distribution.

### AWS Elastic Load Balancing (ELB) — Types

#### Application Load Balancer (ALB) — Layer 7
The most commonly used type. Operates at the HTTP/HTTPS level.

**Features:**
- **Path-based routing** — `/api/*` → backend instances; `/images/*` → S3 or different instances
- **Host-based routing** — `api.example.com` → API servers; `www.example.com` → web servers
- **Header/query string routing** — route based on HTTP headers or query parameters
- **WebSocket** and **HTTP/2** support
- **gRPC** support
- **Native integration with AWS WAF** (Web Application Firewall)
- **Sticky sessions** via cookies (duration-based or application-based)
- Returns HTTP 503 when no healthy targets exist

**Use ALB for:** Web apps, microservices, container-based applications (ECS/EKS), REST APIs.

#### Network Load Balancer (NLB) — Layer 4
Operates at the TCP/UDP/TLS level.

**Features:**
- Extremely high performance — handles millions of requests per second
- **Static IP address** per AZ (useful for whitelisting)
- **Elastic IP support**
- Ultra-low latency
- Preserves source IP address of client
- TLS termination (offload TLS from targets)

**Use NLB for:** Gaming, IoT, real-time communications, financial trading systems, any workload requiring extreme throughput or static IPs.

#### Gateway Load Balancer (GWLB) — Layer 3
Deploys, scales, and manages third-party virtual appliances (firewalls, intrusion detection systems).

**Use GWLB for:** Inline traffic inspection, security appliances.

#### Classic Load Balancer (CLB) — Legacy
Original AWS load balancer, operates at both Layer 4 and 7. **Do not use for new projects** — ALB/NLB are superior in every way.

### Key ALB Concepts

#### Target Groups
A **target group** is a logical grouping of targets (EC2 instances, IPs, Lambda functions, or containers).

- Health checks are configured per target group
- An ALB listener rule routes to a target group
- The same target group can be shared by multiple listener rules
- Supports **weighted target groups** — send 90% of traffic to v1, 10% to v2 (blue/green deployments)

#### Listeners
A **listener** checks for connection requests on a specific port and protocol.

- HTTP:80 listener → redirect to HTTPS:443
- HTTPS:443 listener → forward to target group based on rules

#### Listener Rules
Rules are evaluated in priority order. Each rule has:
- **Conditions** — path pattern, host header, HTTP method, query string, source IP
- **Actions** — forward to target group, redirect, return fixed response, authenticate (Cognito/OIDC)

#### Health Checks
The ALB regularly polls targets. If a target fails N consecutive checks, it is marked unhealthy and removed from rotation.

Configuration:
- Protocol: HTTP/HTTPS
- Path: `/health` (best practice — a lightweight endpoint returning 200)
- Healthy threshold: 2 consecutive successes
- Unhealthy threshold: 5 consecutive failures
- Timeout: 5 seconds
- Interval: 30 seconds

#### SSL/TLS Termination
ALB decrypts HTTPS at the load balancer, then communicates with targets over HTTP internally. This offloads the encryption burden from your instances.

- Certificates stored in **AWS Certificate Manager (ACM)** — free
- ALB supports **SNI** — serve multiple certificates for multiple domains on the same HTTPS listener

#### Access Logs
ALB can log every request to S3. Useful for debugging, compliance, and traffic analysis. Fields include:
- Timestamp, client IP, request processing time
- HTTP method, URL, response code
- Target IP, SSL cipher/protocol

### AWS Hands-On: Create an Application Load Balancer

```bash
# Create an ALB
aws elbv2 create-load-balancer \
  --name my-sprint-alb \
  --subnets subnet-xxxxxxxx subnet-yyyyyyyy \
  --security-groups sg-xxxxxxxx \
  --scheme internet-facing \
  --type application

# Create a target group
aws elbv2 create-target-group \
  --name my-sprint-tg \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-xxxxxxxx \
  --health-check-path /health \
  --health-check-interval-seconds 30 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 5

# Create a listener
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:... \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:...

# Register EC2 instances with the target group
aws elbv2 register-targets \
  --target-group-arn arn:aws:elasticloadbalancing:... \
  --targets Id=i-xxxxxxxx Id=i-yyyyyyyy
```

> **Console Path:** EC2 → Load Balancers → Create Load Balancer

### Connecting Load Balancing + Auto Scaling

When combined, the ALB and ASG form the backbone of a scalable, fault-tolerant application:

```
User Request
     │
     ▼
[ALB — distributes traffic]
     │
     ├──► EC2 Instance A  ─┐
     ├──► EC2 Instance B   ├── Auto Scaling Group (min 2, max 8)
     └──► EC2 Instance C  ─┘
                │
           CloudWatch
                │
        Scaling Policy
        (add/remove instances
         based on ALB metrics)
```

The ASG registers new instances with the ALB target group automatically. When scale-in occurs, the ASG deregisters instances from the target group (connection draining) before termination.

**Connection Draining / Deregistration Delay:**
When an instance is removed from the target group (manually or by scale-in), the ALB stops sending new requests but allows in-flight requests up to N seconds (default 300s, configurable) to complete before the instance is terminated. Set lower (e.g., 30s) for fast-response applications.

---

## 5. Suggested 5-Day Schedule

### Day 1 — VPC Foundations
| Time | Activity |
|---|---|
| Morning | Theory: VPC, CIDR, IGW, Route Tables |
| Afternoon Lab | Build a VPC from scratch (no VPC Wizard) — public + private subnets, IGW, route tables |
| Challenge | Lock down a VPC with NACLs and Security Groups |

### Day 2 — Subnet Architecture & Networking
| Time | Activity |
|---|---|
| Morning | Theory: Multi-tier subnet design, NAT Gateway, VPC Peering |
| Afternoon Lab | Deploy a 3-tier subnet architecture; configure NAT Gateway; launch EC2 in private subnet and verify internet access via NAT |
| Challenge | Peer two VPCs and test connectivity |

### Day 3 — Autoscaling Theory & Implementation
| Time | Activity |
|---|---|
| Morning | Theory: Launch Templates, ASG components, scaling policies |
| Afternoon Lab | Create Launch Template + ASG; configure target tracking (CPU 50%); use `stress` tool to trigger scaling |
| Challenge | Configure lifecycle hooks + scheduled scaling |

### Day 4 — Load Balancing
| Time | Activity |
|---|---|
| Morning | Theory: ALB vs NLB, target groups, listeners, health checks |
| Afternoon Lab | Create ALB + target group; register 2 EC2 instances; verify traffic distribution; simulate instance failure |
| Challenge | Configure path-based routing; enable access logs to S3 |

### Day 5 — Integration & Architecture Review
| Time | Activity |
|---|---|
| Morning | Connect the full stack: VPC → subnets → ASG → ALB |
| Afternoon Lab | Full architecture deployment; inject load via Apache Bench (`ab`) and observe scaling + ALB behaviour in CloudWatch |
| Review | Cost analysis using AWS Cost Explorer + architecture review |

---

## 6. AWS CLI Quick Reference

```bash
# VPC
aws ec2 describe-vpcs
aws ec2 describe-subnets
aws ec2 describe-internet-gateways
aws ec2 describe-route-tables
aws ec2 describe-security-groups

# Auto Scaling
aws autoscaling describe-auto-scaling-groups
aws autoscaling describe-scaling-activities --auto-scaling-group-name <name>
aws autoscaling set-desired-capacity --auto-scaling-group-name <name> --desired-capacity 3

# Load Balancing
aws elbv2 describe-load-balancers
aws elbv2 describe-target-groups
aws elbv2 describe-target-health --target-group-arn <arn>

# Useful general
aws ec2 describe-availability-zones --region eu-west-1
aws sts get-caller-identity  # confirm which AWS account/user you are
```

---

## 7. Key Terminology Glossary

| Term | Definition |
|---|---|
| **VPC** | Virtual Private Cloud — isolated network section in AWS |
| **CIDR** | Classless Inter-Domain Routing — IP address range notation (e.g., 10.0.0.0/16) |
| **IGW** | Internet Gateway — enables internet access for a VPC |
| **NAT Gateway** | Allows private subnet resources to reach the internet without being exposed |
| **Route Table** | Rules determining where network traffic is directed |
| **Security Group** | Stateful virtual firewall at the instance level |
| **NACL** | Network ACL — stateless firewall at the subnet level |
| **AZ** | Availability Zone — physically separate data centre within an AWS Region |
| **ASG** | Auto Scaling Group — manages a fleet of EC2 instances |
| **Launch Template** | Blueprint for EC2 instances launched by an ASG |
| **Target Tracking** | Scaling policy that maintains a specified CloudWatch metric value |
| **ALB** | Application Load Balancer — Layer 7 HTTP/HTTPS load balancer |
| **NLB** | Network Load Balancer — Layer 4 TCP/UDP load balancer |
| **Target Group** | Collection of targets that receive traffic from a load balancer |
| **Health Check** | Regular probe to determine if a target is healthy |
| **SSL Termination** | Decrypting HTTPS at the load balancer, forwarding HTTP to targets |
| **ACM** | AWS Certificate Manager — free SSL/TLS certificate management |
| **VPC Peering** | Private connection between two VPCs |
| **VPC Endpoint** | Private connection to AWS services without internet exposure |
| **Sticky Sessions** | ALB sends a client's requests to the same target using cookies |
| **Connection Draining** | Grace period allowing in-flight requests to complete before target removal |
| **OSI Model** | 7-layer conceptual model for how network communication works |
| **DNS** | Domain Name System — translates domain names to IP addresses |
| **Route 53** | AWS managed DNS service with health checks and routing policies |
| **CloudFront** | AWS CDN — caches content at edge locations worldwide |
| **SNI** | Server Name Indication — serve multiple SSL certificates on one listener |
| **Elastic IP** | Static public IPv4 address that you can allocate and associate with resources |
| **Bastion Host** | A hardened EC2 instance in a public subnet used to SSH into private instances |

---

## 8. OSI Model — Networking Foundation

Understanding the OSI model helps you debug connectivity issues during labs. Focus on Layers 3, 4, and 7 — these are what you'll interact with daily.

| Layer | Name | What You Care About | AWS Equivalent |
|-------|------|---------------------|----------------|
| 7 | Application | HTTP, HTTPS, DNS, SSH | ALB, Route 53, API Gateway |
| 4 | Transport | TCP, UDP, ports | NLB, Security Groups (port rules) |
| 3 | Network | IP addresses, routing, subnets | VPC, subnets, route tables, NACLs |
| 2 | Data Link | MAC addresses, switches | (managed by AWS) |
| 1 | Physical | Cables, NICs | (managed by AWS) |

### Debugging: Work Bottom-Up

When something isn't connecting during a lab, follow this order:

```bash
# Layer 3 — Is the host reachable?
ping 10.0.1.50

# Layer 4 — Is the port open?
nc -zv 10.0.1.50 80
telnet 10.0.1.50 80

# Layer 7 — Does the application respond?
curl http://10.0.1.50
curl -v https://example.com
```

---

## 9. DNS & Route 53

### How DNS Works

1. You type `example.com` in browser
2. Browser checks local cache
3. Asks recursive resolver (ISP or `8.8.8.8`)
4. Resolver asks root nameservers → TLD nameservers (`.com`) → authoritative nameserver
5. Returns the IP address
6. Browser connects to that IP

### DNS Record Types

| Type | Purpose | Example |
|------|---------|---------|
| **A** | Domain → IPv4 address | `example.com → 93.184.216.34` |
| **AAAA** | Domain → IPv6 address | `example.com → 2606:2800:...` |
| **CNAME** | Alias → another domain | `www.example.com → example.com` |
| **MX** | Mail server | `example.com → mail.example.com` |
| **TXT** | Text records (verification, SPF) | `v=spf1 include:_spf.google.com` |
| **NS** | Nameserver delegation | `example.com → ns1.awsdns.com` |

### TTL (Time to Live)

- How long DNS resolvers cache a record (in seconds)
- Low TTL (60s) = changes propagate fast, more DNS queries
- High TTL (86400s = 24h) = fewer queries, slower propagation
- **Before a migration:** lower TTL days in advance, switch, then raise TTL

### AWS Route 53

Route 53 is AWS's managed DNS service. It integrates tightly with the networking stack you'll build during this sprint.

**Routing Policies:**
- **Simple** — single resource (one A record)
- **Weighted** — split traffic by percentage (e.g., 90% to v1, 10% to v2)
- **Latency-based** — route to the lowest-latency region
- **Failover** — primary/secondary with health checks
- **Geolocation** — route based on user's location

**Alias Records** — AWS-specific, point to AWS resources (ALB, S3, CloudFront) without CNAME limitations. No charge for alias queries to AWS resources.

```bash
# DNS debugging tools
dig example.com              # Full DNS query
dig example.com +short       # Just the IP
dig @8.8.8.8 example.com    # Query specific DNS server
dig example.com MX           # Query MX records
nslookup example.com
```

---

## 10. Common Ports Reference

These come up repeatedly when configuring security groups and NACLs during the sprint.

| Port | Protocol | Service |
|------|----------|---------|
| 22 | TCP | SSH |
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS |
| 3306 | TCP | MySQL |
| 5432 | TCP | PostgreSQL |
| 27017 | TCP | MongoDB |
| 6379 | TCP | Redis |
| 8080 | TCP | Common alternative HTTP |
| 53 | TCP/UDP | DNS |
| 25 | TCP | SMTP (email) |
| 3000 | TCP | Common dev server (Node, React) |

---

## 11. EC2 Fundamentals for Autoscaling

Before building Auto Scaling Groups, you need to understand the EC2 building blocks.

### Instance Types

| Family | Use Case | Example |
|--------|----------|---------|
| `t3` | General purpose, burstable | Web servers, dev environments |
| `m6i` | General purpose, sustained | Application servers |
| `c6i` | Compute-optimised | CPU-intensive, batch processing |
| `r6i` | Memory-optimised | Databases, in-memory caching |

For sprint labs, `t3.micro` (free tier eligible) is sufficient.

### Pricing Models

| Model | Discount | Commitment | Best For |
|-------|----------|------------|----------|
| On-Demand | None | None | Sprint labs, short-term |
| Reserved | Up to 72% | 1-3 years | Steady production workloads |
| Spot | Up to 90% | None (can be interrupted) | Fault-tolerant, ASG scale-out |
| Savings Plans | Up to 72% | 1-3 years | Flexible commitment |

**Spot + ASG:** Use mixed instance policies — On-Demand for base capacity, Spot for scale-out. If Spot capacity is reclaimed, ASG replaces with On-Demand automatically.

### AMIs (Amazon Machine Images)

- Snapshot of an EC2 instance (OS, software, config)
- Launch Templates reference AMIs to define what instances look like
- AWS provides official AMIs (Ubuntu, Amazon Linux, etc.)
- **Golden AMI pattern:** pre-bake your application into an AMI for faster ASG launches

### User Data

Script that runs on first boot — used in Launch Templates to bootstrap instances:

```bash
#!/bin/bash
apt update -y
apt install -y nginx
systemctl start nginx
systemctl enable nginx
echo "<h1>Hello from $(hostname)</h1>" > /var/www/html/index.html
```

---

## 12. CloudFront — CDN Integration

CloudFront pairs with ALBs to deliver content globally with low latency.

- Caches content at 400+ edge locations worldwide
- Reduces load on your ALB/EC2 origin
- SSL/TLS termination at the edge (free certificates via ACM)
- DDoS protection (integrated with AWS Shield)
- Pairs with S3 for static assets, ALB for dynamic content

### Typical Architecture with ALB

```
User (London)
    │
    ▼
CloudFront Edge (London)
    │ cache miss?
    ▼
ALB (eu-west-1)
    │
    ▼
ASG (EC2 instances)
```

---

## 13. Network Troubleshooting Playbook

Use this during sprint labs when connectivity isn't working.

### "I can't connect to my instance"

```bash
# 1. Is the instance running?
aws ec2 describe-instance-status --instance-ids i-xxxxx

# 2. Can you reach it at all?
ping <public-ip>

# 3. Is the port open?
nc -zv <public-ip> 80
telnet <public-ip> 80

# 4. Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxx

# 5. SSH in and check the service
ssh -i key.pem ubuntu@<public-ip>
sudo systemctl status nginx
ss -tulnp | grep 80

# 6. Check application logs
journalctl -u nginx -f
tail -f /var/log/nginx/error.log
```

### Common Mistakes Checklist

- [ ] Security group doesn't allow the port
- [ ] Service isn't running on the instance
- [ ] Service listening on `localhost` instead of `0.0.0.0`
- [ ] Wrong port number in security group or application
- [ ] NACL blocking return traffic (remember: stateless)
- [ ] Route table missing internet gateway route for public subnet
- [ ] No public IP assigned to instance in public subnet
- [ ] Key pair file permissions too open (need `chmod 400`)
- [ ] NAT Gateway not in a public subnet, or private route table not pointing to it

---

## 14. Cost Awareness for Sprint Labs

### Free Tier Limits (relevant to this sprint)

| Service | Free Allowance |
|---------|---------------|
| EC2 | 750 hours/month `t2.micro` or `t3.micro` |
| ALB | 750 hours/month + 15 LCUs |
| S3 | 5 GB storage |
| CloudWatch | 10 alarms, 1M API requests |
| Data Transfer | 100 GB out/month (first 12 months) |

### What Costs Money in This Sprint

- **NAT Gateway:** ~£0.04/hour + £0.04/GB processed — delete when not in use
- **Elastic IPs:** free when attached to a running instance, charged when unattached
- **ALB:** charged per hour + per LCU — delete after labs
- **Multiple EC2 instances:** watch the 750-hour monthly cap across all instances

### Billing Alarm (set this up on Day 1)

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "Sprint-Billing-Alarm" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --threshold 20 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --alarm-actions arn:aws:sns:us-east-1:<account-id>:billing-alerts \
  --dimensions Name=Currency,Value=USD
```

### Clean-Up Checklist (end of each day)

- [ ] Terminate EC2 instances not needed overnight
- [ ] Delete NAT Gateways (recreate tomorrow)
- [ ] Release unattached Elastic IPs
- [ ] Delete unused load balancers and target groups
- [ ] Check for orphaned EBS volumes

---

*Document prepared for Sparta Education 5-Day Cloud Sprint — AWS hands-on track.*
*Last updated: March 2026*
