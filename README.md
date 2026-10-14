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

## Junior DevOps Role — Learning Notes

The `junior-devops-role/` folder contains 16 detailed standalone learning documents covering the full junior DevOps skill set, indexed by `00-pathway-2026.md` (the strategy doc). Each file provides theory, practical commands, hands-on exercises, and a Completion Bar mapped to the pathway.

When reading through these notes, follow-up questions are expected and encouraged. If a concept needs more clarity or a practical example, ask and the explanation will be added directly into the relevant file. This way the documents grow more useful over time and become a personalised learning resource rather than a static reference.

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

## Local Linux Practice Environment

For day-to-day Linux practice without spinning up AWS instances, I run an Ubuntu VM locally on macOS and SSH into it from the host terminal — same workflow as connecting to a remote EC2 box.

### Setup

- **Host:** macOS (Apple Silicon, zsh)
- **Guest:** Ubuntu 24.04.3 ARM64 in Parallels Desktop
- **VM name:** `Ubuntu 24.04.3 ARM64`
- **Ubuntu user:** `parallels`
- **SSH server:** OpenSSH 9.6 (installed and enabled by default in this Parallels image)

### SSH from macOS

Added to `~/.ssh/config`:

```
Host ubuntu
    HostName 10.211.55.4
    User parallels
```

Connect with:

```bash
ssh ubuntu
```

For passwordless login (recommended once comfortable):

```bash
ssh-copy-id ubuntu
```

### Finding the VM's IP

Parallels assigns IPs via DHCP on the shared network (`10.211.55.x`). If `ssh ubuntu` ever fails, look up the current IP from the host:

```bash
prlctl list --full --info "Ubuntu 24.04.3 ARM64" | grep "IP Addresses"
```

Then update `HostName` in `~/.ssh/config`.

### Useful prlctl commands (host side)

```bash
prlctl list --all                              # show all VMs and state
prlctl start "Ubuntu 24.04.3 ARM64"            # start
prlctl stop  "Ubuntu 24.04.3 ARM64"            # graceful shutdown
prlctl stop  "Ubuntu 24.04.3 ARM64" --kill     # force stop
prlctl set   "Ubuntu 24.04.3 ARM64" --select-boot-device on   # show boot picker
```

### Password recovery (GRUB → init=/bin/bash)

If the Ubuntu password is forgotten, recover from the GRUB command line (`c` from the GRUB menu) by manually loading the kernel with `init=/bin/bash`:

```
set root=(hd0,gpt2)
linux /boot/vmlinuz-<version>-generic root=/dev/sda2 rw init=/bin/bash
initrd /boot/initrd.img-<version>-generic
boot
```

Then in the bash shell:

```bash
mount -o remount,rw /
ls /home                       # confirm username
passwd <username>
exec /sbin/init 6              # reboot
```

To get into GRUB reliably on Parallels ARM64: enable `--select-boot-device on`, press `Esc` at the boot picker, hold Left Shift through the firmware handoff, then press `c` from the GRUB menu.

---

