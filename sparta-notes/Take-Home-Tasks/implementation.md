# Take-Home Tasks — Implementation Guide

This guide walks through each optional task step-by-step, building on the Sparta app you already have deployed.

**Prerequisites for all tasks:**
- GitHub account with `sparta-test-app` repo (from Day 2)
- Docker Desktop installed on your Mac ([download here](https://www.docker.com/products/docker-desktop/))
- AWS account (from the sprint)

---

## Optional 1: CI/CD Pipeline with GitHub Actions

### What you're building

A pipeline that automatically runs tests every time you push code to GitHub. If the tests pass, the code is safe to deploy.

```
You push code → GitHub Actions triggers → Install deps → Run tests → ✅ or ❌
```

### Concepts to understand first

| Term | Meaning |
|---|---|
| **CI (Continuous Integration)** | Every code push triggers an automated build and test. Catches bugs early. |
| **CD (Continuous Delivery)** | Code that passes CI is automatically deployed to staging. Production needs manual approval. |
| **CD (Continuous Deployment)** | Every change that passes CI auto-deploys to production. No manual gates. |
| **Workflow** | A YAML file that defines your pipeline (lives in `.github/workflows/`) |
| **Job** | A set of steps that run on the same machine |
| **Runner** | The machine (VM) that executes your jobs — GitHub provides free ones |

### Step 1: Create the workflow file

On your Mac, in the `sparta-test-app` repo:

```bash
cd ~/Documents/MSc-CS/sparta/sparta_app/nodejs20-se-test-app-2025
mkdir -p .github/workflows
```

Create `.github/workflows/ci.yml`:

```yaml
name: Sparta App CI

# When to run this pipeline
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    # Run on a GitHub-provided Ubuntu VM
    runs-on: ubuntu-latest

    steps:
      # 1. Check out the code from the repo
      - name: Checkout code
        uses: actions/checkout@v4

      # 2. Set up Node.js 20 (same version we use on EC2)
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      # 3. Install dependencies
      - name: Install dependencies
        run: npm install
        working-directory: ./app

      # 4. Run tests
      - name: Run tests
        run: npm test
        working-directory: ./app
```

### Step 2: Push and watch it run

```bash
git add .github/workflows/ci.yml
git commit -m "Add CI pipeline with GitHub Actions"
git push origin main
```

Then go to your repo on GitHub → **Actions** tab → you should see the workflow running.

### Step 3: Verify it works

- **Green checkmark** = tests passed
- **Red X** = something failed — click into the job to see logs
- Every future push to `main` or PR against `main` will trigger this pipeline

### Step 4 (Stretch): Add a test stage that uses MongoDB

If you want the CI pipeline to also test the `/posts` route (which needs MongoDB), add a **service container**:

```yaml
name: Sparta App CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    # Spin up MongoDB as a service alongside your tests
    services:
      mongodb:
        image: mongo:7.0
        ports:
          - 27017:27017

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm install
        working-directory: ./app

      - name: Seed database
        run: node seeds/seed.js
        working-directory: ./app
        env:
          DB_HOST: mongodb://localhost:27017/posts

      - name: Run tests
        run: npm test
        working-directory: ./app
        env:
          DB_HOST: mongodb://localhost:27017/posts
```

This mirrors the two-tier architecture from Day 3 — but entirely inside the CI pipeline.

### Understanding the workflow file

| Line | What it does |
|---|---|
| `on: push: branches: [main]` | Trigger on push to main branch |
| `on: pull_request` | Also trigger when a PR is opened |
| `runs-on: ubuntu-latest` | Use a GitHub-hosted Ubuntu VM |
| `uses: actions/checkout@v4` | Clone your repo onto the runner |
| `uses: actions/setup-node@v4` | Install Node.js on the runner |
| `run: npm install` | Run a shell command |
| `working-directory: ./app` | Run the command from the `app/` folder |
| `services: mongodb:` | Start a MongoDB container alongside the job |
| `env: DB_HOST:` | Set environment variable (just like `export` on EC2) |

---

## Optional 2: Docker & Containerisation

### What you're building

Package the Sparta app into a Docker container, then use Docker Compose to run both the app and MongoDB in containers — no EC2 required.

```
Before (Day 3):                          After (Docker):
┌──────────┐    ┌──────────┐             ┌──────────────────────────┐
│ App EC2  │───►│ DB EC2   │             │    Your Mac (Docker)     │
│ Node.js  │    │ MongoDB  │             │ ┌─────────┐ ┌─────────┐ │
└──────────┘    └──────────┘             │ │ app     │►│ mongodb │ │
  2 instances, manual setup              │ │container│ │container│ │
                                          │ └─────────┘ └─────────┘ │
                                          └──────────────────────────┘
                                            1 command: docker compose up
```

### Concepts to understand first

| Term | Meaning |
|---|---|
| **Image** | A read-only template containing your app + everything it needs to run (like an AMI) |
| **Container** | A running instance of an image (like an EC2 instance launched from an AMI) |
| **Dockerfile** | Instructions to build an image (like a deployment script) |
| **Docker Hub** | Public registry for images (like GitHub but for Docker images) |
| **Docker Compose** | Tool to run multiple containers together (like launching app + DB instances) |
| **Volume** | Persistent storage that survives container restarts (like an EBS volume) |

### Step 1: Create a Dockerfile for the Sparta app

In your `sparta-test-app` repo, create `app/Dockerfile`:

```dockerfile
# Use Node.js 20 on Alpine Linux (small image)
FROM node:20-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy package files first (for better caching)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the app code
COPY . .

# The app listens on port 3000
EXPOSE 3000

# Start the app
CMD ["node", "app.js"]
```

### Understanding the Dockerfile

| Instruction | What it does | Equivalent on EC2 |
|---|---|---|
| `FROM node:20-alpine` | Base image with Node.js pre-installed | Ubuntu AMI + `apt install nodejs` |
| `WORKDIR /app` | Set working directory | `cd ~/sparta-test-app/app` |
| `COPY package*.json ./` | Copy package files into container | `scp` files to instance |
| `RUN npm install` | Install dependencies at build time | `npm install` on instance |
| `COPY . .` | Copy all app files | `git clone` the app |
| `EXPOSE 3000` | Document which port the app uses | Security group port 3000 |
| `CMD ["node", "app.js"]` | Default command when container starts | `pm2 start app.js` |

### Step 2: Create a .dockerignore file

Create `app/.dockerignore` to exclude unnecessary files:

```
node_modules
npm-debug.log
.git
.env
```

### Step 3: Build and run the app container

```bash
cd ~/Documents/MSc-CS/sparta/sparta_app/nodejs20-se-test-app-2025/app

# Build the image (the dot means "use current directory")
docker build -t sparta-app .

# Run the container
docker run -d -p 3000:3000 --name sparta-app sparta-app
```

| Flag | Meaning |
|---|---|
| `-d` | Detached mode (run in background, like pm2) |
| `-p 3000:3000` | Map port 3000 on your Mac to port 3000 in the container |
| `--name sparta-app` | Give the container a friendly name |

Visit `http://localhost:3000` — you should see the Sparta app homepage.

### Step 4: Useful Docker commands

```bash
# See running containers
docker ps

# See all containers (including stopped)
docker ps -a

# View container logs (like pm2 logs)
docker logs sparta-app

# Stop the container
docker stop sparta-app

# Remove the container
docker rm sparta-app

# Remove the image
docker rmi sparta-app
```

### Step 5: Push to Docker Hub

```bash
# Create a Docker Hub account at https://hub.docker.com

# Log in from terminal
docker login

# Tag the image with your Docker Hub username
docker tag sparta-app hakimz78/sparta-app:v1

# Push to Docker Hub
docker push hakimz78/sparta-app:v1
```

Replace `hakimz78` with your actual Docker Hub username.

Now anyone can pull and run your app with:
```bash
docker pull hakimz78/sparta-app:v1
docker run -d -p 3000:3000 hakimz78/sparta-app:v1
```

### Step 6: Docker Compose — app + MongoDB together

This is the big one — run both the app and database with a single command.

Create `docker-compose.yml` in the repo root (`nodejs20-se-test-app-2025/`):

```yaml
services:
  mongodb:
    image: mongo:7.0
    container_name: sparta-db
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db

  app:
    build: ./app
    container_name: sparta-app
    ports:
      - "3000:3000"
    environment:
      - DB_HOST=mongodb://mongodb:27017/posts
    depends_on:
      - mongodb

volumes:
  mongo-data:
```

### Understanding docker-compose.yml

| Line | What it does | Equivalent from the sprint |
|---|---|---|
| `services:` | Define the containers to run | Launching 2 EC2 instances |
| `image: mongo:7.0` | Use official MongoDB 7.0 image | Our `deploy-mongo-db.sh` script |
| `volumes: mongo-data:/data/db` | Persist database data | The EBS volume on the DB instance |
| `build: ./app` | Build from the Dockerfile in `./app` | Our `deploy-sparta-app.sh` script |
| `environment: DB_HOST=...` | Set env var | `export DB_HOST=mongodb://...` |
| `mongodb://mongodb:27017` | `mongodb` = the service name (Docker resolves it as a hostname) | Using the DB private IP |
| `depends_on: mongodb` | Start MongoDB before the app | "Always deploy DB first" (Day 3 rule) |

### Step 7: Run with Docker Compose

```bash
cd ~/Documents/MSc-CS/sparta/sparta_app/nodejs20-se-test-app-2025

# Start both containers
docker compose up -d

# Check they're running
docker compose ps

# View app logs
docker compose logs app

# View MongoDB logs
docker compose logs mongodb
```

Visit:
- `http://localhost:3000` — Sparta app homepage
- `http://localhost:3000/posts` — posts page (may need seeding first)

### Step 8: Seed the database

```bash
# Run the seed script inside the running app container
docker compose exec app node seeds/seed.js
```

Now visit `http://localhost:3000/posts` — you should see post data.

### Step 9: Stop and clean up

```bash
# Stop containers (keeps data in volume)
docker compose down

# Stop AND delete the database volume (fresh start next time)
docker compose down -v
```

### Docker vs EC2 comparison

| | EC2 (Days 1-5) | Docker (this task) |
|---|---|---|
| Setup time | 15-30 min (scripts + SSH) | ~2 min (`docker compose up`) |
| Portability | AWS-only | Runs anywhere Docker is installed |
| Cost | EC2 instance charges | Free on your Mac |
| Reproducibility | Scripts can drift, AMIs are large | Dockerfile = exact same build every time |
| Teardown | Terminate instances, clean up SGs | `docker compose down` |
| Production use | Direct EC2, ASG + ALB | ECS Fargate, EKS (Kubernetes) |

---

## Optional 3: Deploy Your Own Web App (Full SDLC)

### Overview

Build or deploy a personal project using everything from the sprint. This is portfolio material.

### Phase 1: Plan

1. **Choose your app** — either something you already have, or a simple new project:
   - A portfolio website (HTML/CSS/JS)
   - A Node.js API with a database
   - A Python Flask/Django app
   - The Sparta app with your own modifications

2. **Define requirements**:
   - What does the app do?
   - What tech stack? (Node.js, Python, etc.)
   - Does it need a database?
   - What ports does it use?

3. **Architecture diagram** — draw what you're building:
   ```
   User → Nginx (port 80) → Your App (port 3000) → Database (port 27017)
   ```

### Phase 2: Code

1. **Set up a GitHub repo**:
   ```bash
   mkdir my-project && cd my-project
   git init
   gh repo create my-project --public --source=. --push
   ```

2. **Write your app** (or copy an existing one)

3. **Add a `.gitignore`**:
   ```
   node_modules/
   .env
   *.pem
   ```

### Phase 3: Build & Test

1. **Write a Dockerfile** (see Optional 2 above for the pattern)

2. **Test locally with Docker Compose**:
   ```bash
   docker compose up -d
   # Visit http://localhost:3000
   ```

3. **Add a CI pipeline** (see Optional 1 above):
   - Create `.github/workflows/ci.yml`
   - Run tests on every push

### Phase 4: Deploy to AWS

Use the techniques from the sprint. Choose your level:

#### Level 1: Manual (Day 2 approach)
```bash
# Launch EC2, SCP your code, SSH in, run your deploy script
scp -i ~/.ssh/se-zaehid-key-pair.pem -r ./my-project ubuntu@<PUBLIC-IP>:~/
ssh -i ~/.ssh/se-zaehid-key-pair.pem ubuntu@<PUBLIC-IP>
# Run your deployment script
```

#### Level 2: AMI + User Data (Day 4 approach)
1. Deploy manually once
2. Create an AMI
3. Write a User Data script
4. Launch from AMI with User Data — zero SSH

#### Level 3: ASG + ALB (Day 5 approach)
1. Create a Launch Template from your AMI
2. Create an ASG (min 2, max 3, CPU target 50%)
3. Attach a Load Balancer
4. Access via the LB DNS name

#### Level 4: Docker on EC2
1. Launch an EC2 instance
2. Install Docker:
   ```bash
   sudo apt update -y
   sudo apt install docker.io docker-compose-v2 -y
   sudo systemctl start docker
   sudo systemctl enable docker
   sudo usermod -aG docker ubuntu
   # Log out and back in for group change to take effect
   ```
3. Copy your `docker-compose.yml` and `Dockerfile` to the instance
4. Run:
   ```bash
   docker compose up -d
   ```

### Phase 5: CI/CD (Stretch)

Extend your GitHub Actions pipeline to automatically deploy on push to main:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm install
        working-directory: ./app
      - run: npm test
        working-directory: ./app

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to EC2
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.EC2_HOST }}
          username: ubuntu
          key: ${{ secrets.EC2_SSH_KEY }}
          script: |
            cd ~/my-project
            git pull origin main
            cd app
            npm install
            pm2 restart my-app
```

To set this up:
1. GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. Add `EC2_HOST` = your EC2 public IP
3. Add `EC2_SSH_KEY` = contents of your `.pem` file

### Phase 6: Monitor

- Set up **CloudWatch** dashboards and alarms (Day 4 techniques)
- CPU alarm > 50% with SNS email notification
- Check `pm2 logs` or `docker compose logs` for app errors

### Phase 7: Document

Create a `README.md` in your repo with:
- What the app does
- Architecture diagram
- How to run locally
- How to deploy
- Screenshots of the app running
- Link to the CI pipeline

This is **portfolio material** — something you can link on your CV and talk about in interviews.

---

## Summary: What each task demonstrates

| Task | Skills demonstrated |
|---|---|
| **Optional 1: CI/CD** | GitHub Actions, automation, testing, pipeline design |
| **Optional 2: Docker** | Containerisation, Dockerfile, Docker Compose, Docker Hub |
| **Optional 3: Full SDLC** | End-to-end delivery, AWS deployment, monitoring, documentation |

All three tasks build directly on what you did during the sprint — same app, same concepts, just more automation.
