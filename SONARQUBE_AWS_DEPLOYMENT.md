# SonarQube AWS Deployment Guide - SafeZone

SonarQube will be deployed to AWS alongside your other services. This guide shows how to set it up.

## Overview

- **Deployment:** AWS EC2 (same server as Jenkins)
- **Access URL:** `http://YOUR_AWS_IP:9000`
- **Deployed via:** Jenkins pipeline (automatic)
- **Database:** PostgreSQL (containerized with SonarQube)

## Prerequisites

✅ AWS EC2 instance running (you already have this)
✅ Docker and docker-compose on AWS (you already have this)
✅ Jenkins configured with AWS credentials (you already have this)
✅ Port 9000 open in AWS Security Group (need to add this)

## Step 1: Update AWS Security Group ⚠️ IMPORTANT

Before deploying, add port 9000 to your AWS Security Group:

1. Go to AWS Console → EC2 → Security Groups
2. Find your instance's security group
3. Add **Inbound Rule:**
   - **Type:** Custom TCP
   - **Port:** 9000
   - **Source:** Your IP or 0.0.0.0/0 (for testing)
   - **Description:** SonarQube Web UI

Without this, you won't be able to access SonarQube!

## Step 2: Push Code to GitHub

SonarQube will deploy automatically when you push:

```bash
git push origin othmane
```

Jenkins will:
1. Build your application
2. Deploy docker-compose to AWS
3. **Start SonarQube + PostgreSQL on AWS**
4. Run code analysis
5. Check quality gate

## Step 3: Access SonarQube on AWS

Once deployed, access SonarQube at:

```
http://YOUR_AWS_IP:9000
```

Replace `YOUR_AWS_IP` with your actual AWS EC2 public IP (same as Jenkins).

**Default credentials:**
- Username: `admin`
- Password: `admin`

⚠️ **Change password immediately after first login!**

## Step 4: Generate Token

1. Log in to SonarQube on AWS
2. Click profile → **My Account** → **Security**
3. Generate Token:
   - Name: `Jenkins Pipeline`
   - Type: `Global Analysis Token`
   - Expires: `No expiration`
4. **Copy the token**

Example: `squ_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0`

## Step 5: Add Token to Jenkins

1. Open Jenkins: `http://YOUR_JENKINS_URL:8080`
2. **Manage Jenkins** → **Credentials**
3. Click **Add Credentials**
4. Configure:
   - **Kind:** Secret text
   - **Secret:** Paste SonarQube token
   - **ID:** `sonarqube-token` (must match exactly!)
   - **Description:** SonarQube AWS token
5. Click **Create**

## Step 6: Configure Jenkins SonarQube Plugin

### Install Plugin

1. **Manage Jenkins** → **Plugins**
2. Search: "SonarQube Scanner"
3. Install **SonarQube Scanner for Jenkins**
4. Restart Jenkins if prompted

### Configure Server

1. **Manage Jenkins** → **System**
2. Scroll to **SonarQube servers**
3. Click **Add SonarQube**
4. Configure:
   - **Name:** `SonarQube` (must match exactly!)
   - **Server URL:** `http://YOUR_AWS_IP:9000`
   - **Token:** Select `sonarqube-token`
5. **Save**

## Step 7: Test the Pipeline

Push another commit to trigger analysis:

```bash
git commit --allow-empty -m "test: trigger SonarQube analysis"
git push origin othmane
```

Watch Jenkins console output for:
```
🔍 Running SonarQube Code Analysis...
✅ Quality Gate passed with status: OK
```

## How It Works

### Deployment Flow:
```
Push to GitHub
    ↓
Jenkins Webhook
    ↓
Jenkins builds Docker images
    ↓
Jenkins deploys to AWS
    ↓
docker-compose starts:
  - MongoDB
  - Kafka
  - Services
  - Frontend
  - SonarQube + PostgreSQL ← NEW!
    ↓
Jenkins runs SonarQube analysis on AWS
    ↓
Quality gate check
    ↓
Deploy or fail based on quality
```

### Network Setup:
- **Frontend:** Port 4201 (HTTPS)
- **API Gateway:** Port 8443 (HTTPS)
- **Jenkins:** Port 8080
- **SonarQube:** Port 9000 ← NEW!

All services on the same AWS EC2 instance.

## Verifying Deployment

### Check SonarQube is Running

SSH to AWS:
```bash
ssh -i ~/Downloads/lastreal.pem ec2-user@YOUR_AWS_IP

# Check SonarQube containers
docker ps | grep sonar

# Should see:
# buy01-sonarqube
# buy01-sonarqube-db
```

### Check Logs

```bash
# SonarQube logs
docker logs buy01-sonarqube

# Look for: "SonarQube is operational"

# Database logs
docker logs buy01-sonarqube-db
```

### Test Access

From your browser:
```
http://YOUR_AWS_IP:9000
```

Should see SonarQube login page.

## Troubleshooting

### Can't access http://YOUR_AWS_IP:9000

**Problem:** Security group not configured

**Solution:**
1. Check AWS Security Group has port 9000 open
2. Check SonarQube container is running: `docker ps | grep sonarqube`
3. Check SonarQube logs: `docker logs buy01-sonarqube`

### SonarQube container not starting

**Problem:** Insufficient memory or disk space

**Solution:**
```bash
# Check disk space
df -h

# Check memory
free -h

# SonarQube needs at least 2GB RAM
# If low, restart or upgrade instance
```

### Jenkins can't connect to SonarQube

**Problem:** URL misconfigured or token wrong

**Solution:**
1. Verify Jenkins SonarQube server URL: `http://YOUR_AWS_IP:9000`
2. Check token is correct in Jenkins credentials
3. Ensure SonarQube is accessible from Jenkins (they're on same server, so should work)

### Quality gate always fails

**Solution:**
1. Open SonarQube: `http://YOUR_AWS_IP:9000`
2. Go to your project dashboard
3. Click **Quality Gate** tab
4. See which conditions are failing
5. Fix the code issues
6. Push again

## Environment Variables

The pipeline automatically sets:
- `SONARQUBE_URL=http://YOUR_AWS_IP:9000`
- `SONARQUBE_TOKEN=<from Jenkins credentials>`

Maven uses: `${env.SONARQUBE_URL}` from pom.xml

## Security Considerations

### Production Recommendations:

1. **Restrict port 9000** to your team's IPs only
2. **Change default password** immediately
3. **Enable authentication** for all users
4. **Use HTTPS** (optional but recommended)
5. **Regular backups** of SonarQube data

### Security Group Configuration:

**Minimal (Recommended):**
- Port 9000: Only your office/VPN IP

**Testing (Less secure):**
- Port 9000: 0.0.0.0/0 (anywhere)

## Costs

SonarQube runs on your existing EC2 instance:
- **Additional CPU:** ~10-15%
- **Additional RAM:** ~2GB
- **Additional Storage:** ~5-10GB

If your instance is small (t2.micro/small), consider upgrading to t2.medium.

## What's Different from Local?

| Feature | Local | AWS |
|---------|-------|-----|
| Access URL | localhost:9000 | YOUR_AWS_IP:9000 |
| Deployment | Manual docker-compose | Automatic via Jenkins |
| Persistence | Local volumes | AWS EBS volumes |
| Security | No firewall needed | Security group port 9000 |
| Access | Only you | Team (if security group allows) |

## Next Steps

1. ✅ Update AWS Security Group (port 9000)
2. ✅ Push code to GitHub
3. ✅ Wait for deployment (~5 minutes)
4. ✅ Access SonarQube on AWS
5. ✅ Generate token
6. ✅ Add token to Jenkins
7. ✅ Configure Jenkins plugin
8. ✅ Push again to test
9. ✅ Review code quality results
10. ✅ Fix any issues

## Quick Commands

```bash
# SSH to AWS
ssh -i ~/Downloads/lastreal.pem ec2-user@YOUR_AWS_IP

# Check SonarQube status
docker ps | grep sonar

# View logs
docker logs -f buy01-sonarqube

# Restart SonarQube
cd /home/ec2-user/buy-01-app
docker-compose restart sonarqube

# Check all services
docker ps

# Check disk space
df -h
```

---

**You're all set!** 🚀

SonarQube will now run on AWS and analyze your code automatically on every push.
