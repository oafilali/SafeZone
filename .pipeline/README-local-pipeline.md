# Local CI/CD Pipeline Setup Guide

Complete guide for running the SafeZone CI/CD pipeline locally on macOS with Jenkins, SonarQube, and GitHub webhooks via ngrok.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Configuration](#configuration)
- [GitHub Webhook Setup](#github-webhook-setup)
- [Testing the Pipeline](#testing-the-pipeline)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)

---

## Overview

This setup allows you to run the complete CI/CD pipeline locally without AWS infrastructure. The pipeline includes:

- ✅ **Jenkins** - CI/CD automation server
- ✅ **SonarQube** - Code quality and security analysis
- ✅ **ngrok** - GitHub webhook tunnel to local Jenkins
- ✅ **Docker** - Application deployment
- ✅ **Maven** - Backend build tool
- ✅ **Node.js/npm** - Frontend build tool

---

## Architecture

```
GitHub Push Event
    ↓
GitHub Webhook → ngrok → Local Jenkins (port 8080)
                              ↓
                         Build & Test
                              ↓
                    SonarQube Analysis (localhost:9000)
                              ↓
                         Quality Gate
                              ↓
                    Deploy via Docker Compose
                              ↓
                    Application Running Locally
```

---

## Prerequisites

### Required

- **macOS** (10.15 or later)
- **8GB RAM** minimum (16GB recommended)
- **20GB free disk space**
- **Docker Desktop** installed and running
- **Admin/sudo** access
- **GitHub repository** admin access

### Will Be Installed Automatically

- Homebrew
- Java 17
- Maven
- Node.js 20
- Angular CLI
- Jenkins LTS
- ngrok

---

## Quick Start

```bash
# 1. Navigate to the pipeline directory
cd /Users/othmane.afilali/Desktop/antigravity/SafeZone/.pipeline

# 2. Make scripts executable
chmod +x *.sh

# 3. Run the complete setup (20-30 minutes)
./setup-all-local.sh

# 4. Follow the on-screen instructions to:
#    - Complete Jenkins initial setup
#    - Configure Jenkins (run setup-local-jenkins.sh)
#    - Configure GitHub webhook
#    - Update Jenkins credentials
```

---

## Detailed Setup

### Step 1: Run Master Setup Script

```bash
cd /Users/othmane.afilali/Desktop/antigravity/SafeZone/.pipeline
./setup-all-local.sh
```

This script will:
1. Install Homebrew (if needed)
2. Verify Docker is running
3. Install Java 17
4. Install Maven
5. Install Node.js 20
6. Install Angular CLI
7. Install ngrok
8. Install Jenkins LTS
9. Start Jenkins service
10. Start SonarQube via Docker
11. Start ngrok tunnel for webhooks

**Time:** ~20-30 minutes (depending on download speeds)

### Step 2: Complete Jenkins Initial Setup

1. Open Jenkins: http://localhost:8080

2. Get the initial admin password:
   ```bash
   cat /opt/homebrew/var/jenkins_home/secrets/initialAdminPassword
   ```

3. Paste the password in the Jenkins setup wizard

4. Choose "Install suggested plugins"

5. Create your admin user account

6. Set Jenkins URL: `http://localhost:8080`

7. Click "Start using Jenkins"

### Step 3: Configure Jenkins

```bash
./setup-local-jenkins.sh
```

Enter your Jenkins admin credentials when prompted.

This script will:
- Install required Jenkins plugins
- Create placeholder credentials
- Create the SafeZone pipeline job
- Configure SonarQube server integration

### Step 4: Configure SonarQube

1. Open SonarQube: http://localhost:9000

2. Login with default credentials:
   - **Username:** `admin`
   - **Password:** `admin`

3. Change the password when prompted

4. Generate an authentication token:
   - Click on your avatar (top right) → My Account
   - Go to Security tab
   - Generate Tokens section
   - Name: `Jenkins`
   - Type: User Token
   - Expires in: No expiration
   - Click Generate
   - **SAVE THIS TOKEN** - you won't see it again!

5. Add token to Jenkins:
   - Go to Jenkins: http://localhost:8080/credentials/
   - Click on "(global)" domain
   - Find "sonarqube-token" credential
   - Click Update
   - Replace `CHANGE_ME_SONARQUBE_TOKEN` with your actual token
   - Click Save

---

## Configuration

### Jenkins Credentials

Update these credentials at: http://localhost:8080/credentials/

| Credential ID | Type | Where to Get | Example Value |
|---------------|------|--------------|---------------|
| `sonarqube-token` | Secret text | SonarQube → My Account → Security | `squ_a1b2c3d4...` |
| `github-token` | Secret text | GitHub → Settings → Developer settings → Personal access tokens | `ghp_xxxx...` |
| `mongo-root-username` | Secret text | Your choice | `admin` |
| `mongo-root-password` | Secret text | Your choice | `SecurePassword123` |
| `api-gateway-url` | Secret text | Local deployment | `http://localhost:8080` |
| `team-email` | Secret text | Your team email | `team@example.com` |

### GitHub Personal Access Token

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Name: `Jenkins CI`
4. Select scopes:
   - ✅ `repo` (all)
   - ✅ `admin:repo_hook` (for webhooks)
5. Click "Generate token"
6. Copy and save the token
7. Add to Jenkins as `github-token` credential

### Pipeline Job Configuration

1. Go to Jenkins → SafeZone-Pipeline → Configure

2. Update the Git repository URL:
   - Find "Pipeline" section
   - SCM: Git
   - Repository URL: `https://github.com/YOUR_USERNAME/SafeZone.git`
   - Credentials: (add GitHub token if private repo)
   - Branch: `*/main`

3. Save the configuration

---

## GitHub Webhook Setup

### Get ngrok URL

The ngrok URL is displayed when you run `setup-all-local.sh` or `setup-jenkins-webhooks.sh`.

To retrieve it later:
```bash
curl -s http://localhost:4040/api/tunnels | grep -Eo 'https://[a-zA-Z0-9\-]+\.ngrok-free\.app'
```

Or visit the ngrok dashboard: http://localhost:4040

### Configure GitHub Webhook

1. Go to your repository settings:
   ```
   https://github.com/YOUR_USERNAME/SafeZone/settings/hooks
   ```

2. Click "Add webhook"

3. Configure:
   - **Payload URL:** `https://YOUR-NGROK-URL.ngrok-free.app/github-webhook/`
     - ⚠️ Don't forget the trailing slash!
   - **Content type:** `application/json`
   - **Secret:** (leave empty or set one)
   - **Which events:** Just the push event
   - **Active:** ✓ Checked

4. Click "Add webhook"

5. Verify webhook:
   - You should see a green checkmark ✅ after the first ping
   - If red ❌, check ngrok is running and URL is correct

---

## Testing the Pipeline

### Test 1: Manual Trigger

1. Go to Jenkins: http://localhost:8080
2. Click on "SafeZone-Pipeline"
3. Click "Build Now"
4. Watch the build progress in Console Output

### Test 2: Git Push Trigger

1. Create a test branch:
   ```bash
   cd /Users/othmane.afilali/Desktop/antigravity/SafeZone
   git checkout -b test-pipeline
   ```

2. Make a small change:
   ```bash
   echo "# Test" >> README.md
   git add README.md
   git commit -m "Test pipeline trigger"
   git push origin test-pipeline
   ```

3. Check Jenkins:
   - A new build should start automatically
   - Check GitHub webhook deliveries to verify

4. Monitor the build:
   - Jenkins console: http://localhost:8080
   - SonarQube analysis: http://localhost:9000/projects

---

## Troubleshooting

### Jenkins Won't Start

**Problem:** Jenkins service fails to start

**Solution:**
```bash
# Check status
brew services list | grep jenkins

# Restart Jenkins
brew services restart jenkins-lts

# Check logs
tail -f /opt/homebrew/var/log/jenkins-lts/jenkins-lts.log
```

### ngrok Tunnel Not Working

**Problem:** GitHub webhook can't reach Jenkins

**Solution:**
```bash
# Stop any existing ngrok processes
pkill -f ngrok

# Restart ngrok
./setup-jenkins-webhooks.sh

# Verify ngrok is running
curl -s http://localhost:4040/api/tunnels

# Update GitHub webhook with new ngrok URL
```

### SonarQube Won't Start

**Problem:** SonarQube container fails

**Solution:**
```bash
# Check Docker
docker ps -a | grep sonarqube

# View logs
docker logs buy01-sonarqube

# Restart SonarQube
cd /Users/othmane.afilali/Desktop/antigravity/SafeZone/.pipeline
docker-compose restart sonarqube

# If database issues, restart database too
docker-compose restart sonarqube-db sonarqube
```

### Pipeline Fails at SonarQube Analysis

**Problem:** Quality gate check fails

**Solutions:**

1. **Token issue:**
   - Verify token in Jenkins credentials
   - Generate new token in SonarQube
   
2. **Connection issue:**
   ```bash
   # From Jenkins machine, test connection
   curl -u YOUR_TOKEN: http://localhost:9000/api/system/status
   ```

3. **Quality gate too strict:**
   - Login to SonarQube
   - Go to Quality Gates
   - Review/adjust thresholds

### Build Fails - Dependencies

**Problem:** Maven or npm install fails

**Solution:**
```bash
# Clear Maven cache
rm -rf ~/.m2/repository

# Clear npm cache
npm cache clean --force

# Retry build in Jenkins
```

### Port Already in Use

**Problem:** Port 8080 or 9000 already in use

**Solution:**
```bash
# Find what's using the port
lsof -i :8080
lsof -i :9000

# Kill the process (if safe)
kill -9 <PID>

# Or configure Jenkins/SonarQube to use different ports
```

### Docker Out of Space

**Problem:** Docker runs out of disk space

**Solution:**
```bash
# Clean up Docker
docker system prune -a --volumes

# Remove unused images
docker image prune -a

# Check disk usage
docker system df
```

---

## Maintenance

### Updating Jenkins

```bash
# Update Jenkins
brew upgrade jenkins-lts

# Restart Jenkins
brew services restart jenkins-lts
```

### Updating SonarQube

```bash
cd /Users/othmane.afilali/Desktop/antigravity/SafeZone/.pipeline

# Stop current version
docker-compose stop sonarqube

# Update image in docker-compose.yml (change version tag)
# Then pull new image
docker-compose pull sonarqube

# Start updated version
docker-compose up -d sonarqube
```

### Backing Up Jenkins

```bash
# Backup Jenkins home directory
tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz /opt/homebrew/var/jenkins_home

# Store backup safely
mv jenkins-backup-*.tar.gz ~/Documents/Backups/
```

### Backing Up SonarQube

```bash
# Backup SonarQube data
docker run --rm \
  -v pipeline_sonarqube_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/sonarqube-backup-$(date +%Y%m%d).tar.gz /data
```

### Stopping All Services

```bash
# Stop Jenkins
brew services stop jenkins-lts

# Stop ngrok
pkill -f ngrok

# Stop SonarQube and application
cd /Users/othmane.afilali/Desktop/antigravity/SafeZone/.pipeline
docker-compose stop
```

### Starting All Services

```bash
# Start Jenkins
brew services start jenkins-lts

# Start SonarQube
./setup-sonarqube.sh

# Start ngrok for webhooks
./setup-jenkins-webhooks.sh

# Start application (after successful build)
cd /Users/othmane.afilali/Desktop/antigravity/SafeZone/.pipeline
docker-compose up -d
```

---

## Useful Commands

```bash
# Check all services status
brew services list | grep jenkins
docker ps | grep -E "sonarqube|buy-01"
pgrep -f ngrok

# View Jenkins logs
tail -f /opt/homebrew/var/log/jenkins-lts/jenkins-lts.log

# View SonarQube logs
docker logs -f buy01-sonarqube

# View ngrok dashboard
open http://localhost:4040

# Access Jenkins CLI
java -jar /opt/homebrew/var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080 -auth admin:PASSWORD help
```

---

## Security Notes

> [!WARNING]
> **Production Considerations**
> - ngrok exposes your local Jenkins to the internet
> - Use strong passwords forJenkins and SonarQube
> - Consider using ngrok's authentication features
> - Don't commit credentials to version control
> - Regularly update all components

---

## Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [ngrok Documentation](https://ngrok.com/docs)
- [Docker Documentation](https://docs.docker.com/)

---

**Need Help?** Check the troubleshooting section or review the logs for errors.
