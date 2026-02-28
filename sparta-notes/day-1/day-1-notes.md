# Day 1 - Cloud Computing & EC2 Deployment

## Cloud Intro

### What is Cloud Computing?
- On-demand delivery of computing resources (servers, storage, databases, networking, software) over the internet
- Instead of owning and maintaining physical data centres, you rent access to resources from a cloud provider
- Pay-as-you-go pricing model — only pay for what you use

### How do we know if something is in the cloud?
- If the service is accessed over the internet and hosted on remote servers managed by a third party, it's in the cloud
- If you don't manage the underlying physical hardware, it's likely cloud-based
- Examples: Gmail, Dropbox, Netflix — all cloud-based services

### Cloud Deployment Models
- **Public Cloud** — resources owned and operated by a third-party provider (e.g. AWS, Azure, GCP), shared across multiple organisations
- **Private Cloud** — cloud infrastructure used exclusively by a single organisation, can be on-premises or hosted
- **Hybrid Cloud** — combination of public and private clouds, allowing data and applications to move between them

### 3 Main Cloud Service Types
- **IaaS (Infrastructure as a Service)** — rent virtual machines, storage, networking. You manage the OS and everything above it (e.g. AWS EC2)
- **PaaS (Platform as a Service)** — provider manages the infrastructure and OS, you deploy your applications (e.g. AWS Elastic Beanstalk, Heroku)
- **SaaS (Software as a Service)** — fully managed software accessed via browser (e.g. Gmail, Slack, Office 365)

### Benefits of Cloud Computing
- **Scalability** — scale resources up/down based on demand
- **Cost efficiency** — no upfront hardware costs, pay only for what you use
- **Reliability** — providers offer high availability and disaster recovery
- **Speed/agility** — provision resources in minutes rather than weeks
- **Global reach** — deploy in multiple regions worldwide

### Pitfalls / Disadvantages
- **Vendor lock-in** — migrating between providers can be difficult
- **Security concerns** — data stored off-premises, shared responsibility model
- **Downtime** — reliant on provider's uptime (AWS outages affect many services)
- **Costs can spiral** — without monitoring, usage costs can grow unexpectedly
- **Compliance** — data residency and regulatory requirements can be complex

### Current Cloud Market Share
- **AWS** — largest share (~31%)
- **Microsoft Azure** — second (~25%)
- **Google Cloud Platform (GCP)** — third (~11%)
- Remaining split between IBM, Oracle, Alibaba, and others

---

## SSH and SSH Key Pairs

### What is SSH?
- **Secure Shell** — a cryptographic network protocol for secure communication over an unsecured network
- Used to remotely access and manage servers via the command line
- Operates on **port 22** by default

### Key and Lock Analogy
- The **public key** is like a lock — you place it on the server (anyone can see the lock)
- The **private key** is like the key to that lock — only you hold it
- When you connect, SSH checks that your private key matches the public key on the server

### Why is the private key sensitive?
- Anyone with your private key can access any server that trusts it
- It should never be shared, emailed, or committed to version control
- If compromised, an attacker has full access to your instances
- Store it securely with restricted file permissions (`chmod 400`)

---

## Virtual Machines / Instances

### What are VMs?
- A **virtual machine** is a software emulation of a physical computer
- Runs its own operating system and applications, isolated from the host machine
- A hypervisor manages and allocates physical resources to each VM

### Why use them?
- **Isolation** — each VM is independent, one crashing doesn't affect others
- **Resource efficiency** — run multiple VMs on a single physical server
- **Testing/development** — spin up environments quickly without dedicated hardware
- **Portability** — VMs can be moved between hosts

### Things to keep in mind when making instances on AWS
- **Region** — choose a region close to your users (e.g. eu-west-1 for Ireland)
- **Instance type** — select based on workload needs (t3.micro for testing/learning)
- **AMI** — choose the right OS image (e.g. Ubuntu 24.04)
- **Key pairs** — use different key pairs for different environments (dev vs production)
- **Security groups** — act as a firewall; only open ports you need
- **Cost** — terminate instances when not in use to avoid charges
- **One instance per person at a time** — don't leave multiple running

---

## EC2 Deployment Steps

1. **Create a key pair** on AWS console
   - Download the `.pem` file
   - Move it from Downloads to a secure location (e.g. `~/.ssh/`)
   - Use a `.` prefix to hide the file if storing locally
   - No file extension needed for the private key on AWS
   - Use different key pairs for production (websites, DBs etc.)

2. **Launch an instance**
   - Name it accordingly (follow naming convention)
   - AMI: **Ubuntu 24.04**
   - Instance type: **t3.micro**
   - Reuse your key pair
   - Reuse your security group (e.g. `se-yourname-basic-sg`)

3. **Edit network settings / security groups**
   - Outbound: open by default
   - Inbound rules:
     - Port **22** = SSH
     - Port **80** = HTTP
     - For HTTPS you need an SSL certificate

4. **Connect to the instance**
   - Locate your `.ssh` folder locally
   - Set key permissions: `chmod 400 your-key.pem` (owner read-only)
   - Use the connect command from the AWS console:
     ```bash
     ssh -i "~/.ssh/your-key.pem" ubuntu@<public-ip-or-dns>
     ```
   - AWS public IP uses dots (`.`), DNS uses dashes (`-`)

5. **Verify you're logged in**
   ```bash
   pwd
   whoami
   uname -a
   ```

6. **Update packages on the server**
   ```bash
   sudo apt update -y
   sudo apt upgrade -y
   ```

7. **Terminate instances by 18:00** — don't leave them running overnight

![EC2 instance](./images/ec2-instance.png)

---

## Nginx Deployment

Install and start the Nginx web server on the EC2 instance:

```bash
sudo apt update -y
sudo apt upgrade -y
sudo apt install nginx -y
```

- After installing, grab the **public IPv4 address** from the AWS console
- Open in browser: `http://<PUBLIC-IP>`
- You should see the default Nginx welcome page
- http(not s-needs SSL)
---

## Automating Nginx Deployment with a Bash Script

### What is a shebang?
- `#!/bin/bash` — the first line of a bash script
- Tells the system which interpreter to use to execute the script
- Without it, the system may not know how to run the file

### Example script (`provision.sh`)
```bash
#!/bin/bash

sudo apt update -y
sudo apt upgrade -y
sudo apt install nginx -y
```

### Getting the script into your EC2 instance
- **Option 1: `scp` (secure copy)**
  ```bash
  scp -i "~/.ssh/your-key.pem" provision.sh ubuntu@<public-ip>:~/
  ```
- **Option 2: Create it directly on the instance**
  ```bash
  nano provision.sh
  ```
- **Option 3: User data** — paste the script into the EC2 "User data" field at launch (runs automatically on first boot)

### Running the script
```bash
chmod +x provision.sh
./provision.sh
```

---

## Extra Tasks

### Task 1: Custom HTML Page

Replace the default Nginx page with your own:

```bash
# SSH into your instance first
# Create a simple HTML page
sudo nano /var/www/html/index.html
```

Paste this:

```html
<!DOCTYPE html>
<html>
<head>
    <title>ZH Cloud Deployment</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #1a1a2e, #16213e);
            color: white;
        }
        .container {
            text-align: center;
        }
        h1 { font-size: 3rem; }
        p { color: #aaa; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Hello from AWS EC2!</h1>
        <p>Deployed by ZH</p>
        <p>Instance: eu-west-1</p>
    </div>
</body>
</html>
```

- Save with `Ctrl+O`, `Enter`, then `Ctrl+X` to exit nano
- Visit your public IP in browser to see it

![Custom HTML page](./images/html.png)

### Task 2: Multi-Page Site

```bash
# Create an about page
sudo nano /var/www/html/about.html
```

- Add content, then visit `http://<your-ip>/about.html`

### Task 3: Automate with User Data

The real learning — terminate your instance and launch a fresh one with this **User Data** script:

```bash
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
```

- This is the key DevOps skill — **infrastructure that configures itself**
- No need for `sudo` in User Data scripts (they run as root)

### Task 4: Create an AMI

Once your instance is configured how you like:

1. **EC2 Console** → Select instance → **Actions** → **Image and templates** → **Create image**
2. Name it `nginx-configured`
3. Launch a new instance from your custom AMI
4. It should start with Nginx already installed

![AMI image](./images/AMI-image.png)
