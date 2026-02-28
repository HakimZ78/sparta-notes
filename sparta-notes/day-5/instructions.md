# Day 5 - Instructions: Auto Scaling Groups & Load Balancers

---

## Create an Auto Scaling Group (ASG)

### Step 1: Choose launch template or configuration

1. Go to **Auto Scaling Groups**
2. Click **Create an Auto Scaling group**
3. Name: `se-name-app-asg`
4. Select the launch template — filter by your first name, then select the one you created
   - If you only have an AMI, you will need to **create a Launch Template first** using the AMI
5. Click **Next**

### Step 2: Choose instance launch options

1. In the **Network** section:
   - VPC: leave as `default-vpc`
   - Availability zones and subnets: tick all 3 AZs in the Ireland region:
     - `eu-west-1a` (DevOpsStudent default 1a)
     - `eu-west-1b` (DevOpsStudent default 1b)
     - `eu-west-1c` (DevOpsStudent default 1c)
2. In **Instance type requirements** — leave as is
3. Click **Next**

### Step 3: Configure advanced options

1. In **Load balancing** section:
   - Select **Attach to a new load balancer**

2. In **Attach to a new load balancer** section:
   - Load balancer type: **Application Load Balancer**
   - Load balancer name: `se-name-app-asg-lb`
   - Load balancer scheme: **Internet-facing**
   - Listeners and routing:
     - Protocol: HTTP
     - Port: 80
     - Default routing: **Create a target group**
     - New target group name: `se-name-app-asg-lb-tg`

3. In **VPC Lattice integration options** — leave as is

4. In **Health checks** section:
   - Tick **Turn on Elastic Load Balancing health checks**
   - Health check grace period: 300 seconds (default)

5. Click **Next**

### Step 4: Configure group size and scaling policies

1. In **Group size** section:
   - Desired capacity: **2**
   - Minimum capacity: **2**
   - Maximum capacity: **3**

2. In **Scaling policies** section:
   - Select **Target tracking scaling policy**
   - Metric type: **Average CPU utilization**
   - Target value: **50** (meaning 50%)

3. In **Instance scale-in protection** — leave unchecked
4. Click **Next**

### Step 5: Add notifications

- Leave as is
- Click **Next**

### Step 6: Add tags

- Click **Add tag**:
  - Key: `Name`
  - Value: `se-name-app-asg`
- **Important!** If you don't add this tag, the instances created by the ASG will not be named!
- Click **Next**

### Step 7: Review

- Check over the details
- Click **Create Auto Scaling group**

---

## Test the Auto Scaling Group

### Access the app via the Load Balancer

1. Go to **Load Balancers**
2. Filter for your load balancer
3. Click on it to go to its **Details**
4. Copy the **DNS name** and paste it into a browser tab
5. Check the app frontpage works (and `/posts` page if connected to database)

### Test self-healing — delete a VM

1. Terminate one of the ASG's VMs
2. Refresh the page immediately — the page may temporarily not work while the Load Balancer detects the unhealthy target
3. Wait — the ASG should automatically launch a replacement instance

---

## Clean Up

This is the only way to stop those VMs from being created:

1. **Delete the Load Balancer**
2. **Delete the Target Group** (if the LB is already gone, it will say "None associated" in the Load balancer column)
3. **Delete the ASG** — this should terminate all related instances (double check)
