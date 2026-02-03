# SafeZone CI/CD Pipeline Setup Guide

This guide helps you set up the SafeZone CI/CD pipeline infrastructure on any computer.

## 📋 Prerequisites

Before starting, ensure you have:

### Required Software

- **Docker Desktop** (includes Docker and Docker Compose)
  - Download: https://www.docker.com/products/docker-desktop
  - Must be running before boot
  - Requires at least 4GB RAM allocated to Docker
- **ngrok** (for GitHub webhook tunneling)

  - Download: https://ngrok.com/download
  - Create account and get auth token: https://dashboard.ngrok.com/auth

- **Git** (for version control)
  - Download: https://git-scm.com/download

### System Requirements

- **Disk Space**: Minimum 10GB available (5GB for Docker images, 5GB for builds)
- **Memory**: 8GB RAM minimum (4GB for Docker, 4GB for host)
- **Network**: Stable internet connection (for npm/Maven dependencies)
- **Ports** available:
  - 8088 (Jenkins)
  - 9000 (SonarQube)
  - 5432 (PostgreSQL)
  - 4040 (ngrok dashboard)

## 🚀 Quick Start

### 1. Verify Prerequisites

```bash
# Check Docker
docker --version
docker-compose --version
docker info  # Verify Docker daemon is running

# Check ngrok
ngrok --version

# Check Git
git --version
```

### 2. Run Boot Script

```bash
# Make script executable
chmod +x boot-pipeline.sh

# Start pipeline
./boot-pipeline.sh
```

**Output:**

- Jenkins: http://localhost:8088
- SonarQube: http://localhost:9000 (admin/admin)
- ngrok public URL: https://your-tunnel.ngrok-free.dev

### 3. Configure ngrok

```bash
# Authenticate ngrok with your token
ngrok config add-authtoken YOUR_TOKEN_HERE
```

### 4. Update GitHub Webhook

1. Go to GitHub repository Settings → Webhooks
2. Update Payload URL to: `{NGROK_URL}/github-webhook/`
3. Keep other settings as-is
4. Save

## 🔧 Boot Script Options

### Basic Usage

```bash
./boot-pipeline.sh
```

### Clean Start (Remove Old Containers)

```bash
./boot-pipeline.sh --cleanup
```

### Rebuild Jenkins Image

```bash
./boot-pipeline.sh --rebuild-jenkins
```

### Local Mode (No ngrok)

```bash
./boot-pipeline.sh --no-ngrok
```

### Full Help

```bash
./boot-pipeline.sh --help
```

## 📊 Jenkins Configuration

### Initial Setup

1. Access Jenkins: http://localhost:8088
2. On first run, you'll see the setup wizard
3. Copy the initial admin password from: `docker logs jenkins-local | grep "The initial admin password"`
4. Complete setup wizard (install recommended plugins)

### Configure SonarQube

1. Manage Jenkins → Configure System
2. Find SonarQube Servers section
3. Add server:
   - Name: `SonarQube`
   - Server URL: `http://host.docker.internal:9000`
   - Server authentication token: (create in SonarQube admin)

### Configure GitHub

1. Manage Jenkins → Configure System
2. GitHub section:
   - GitHub server: https://github.com
   - API URL: https://api.github.com

## 🐛 Troubleshooting

### Jenkins Container Won't Start

```bash
# Check logs
docker logs jenkins-local

# Try cleanup and rebuild
./boot-pipeline.sh --cleanup --rebuild-jenkins
```

### Environment Validation Fails

```bash
# Rebuild Jenkins image with all tools
./boot-pipeline.sh --rebuild-jenkins

# Verify image has tools
docker run --rm jenkins/jenkins:with-tools which mvn
docker run --rm jenkins/jenkins:with-tools which node
docker run --rm jenkins/jenkins:with-tools which chromium
```

### Docker Daemon Not Accessible

```bash
# Verify Docker socket mount
docker exec jenkins-local ls -la /var/run/docker.sock

# Restart Jenkins container
docker restart jenkins-local
```

### No Disk Space

```bash
# Clean up Docker resources
docker system prune -a --volumes

# Remove old images and containers
docker rmi $(docker images -q) --force 2>/dev/null || true
docker rm $(docker ps -a -q) --force 2>/dev/null || true
```

### SonarQube Not Responding

```bash
# Check SonarQube logs
docker logs sonarqube

# Wait longer and try again
sleep 60
curl http://localhost:9000/api/system/health
```

### ngrok Connection Issues

```bash
# Check ngrok status
curl http://localhost:4040/api/tunnels

# Restart ngrok tunnel
pkill -f "ngrok.*http.*8088"
./boot-pipeline.sh  # Will restart ngrok

# Check ngrok logs
cat /tmp/ngrok.log
```

## 🔍 Monitoring

### View Jenkins Logs

```bash
docker logs -f jenkins-local
```

### View SonarQube Logs

```bash
docker logs -f sonarqube
```

### View ngrok Status

```bash
curl http://localhost:4040/api/tunnels | jq .
```

### Check Container Status

```bash
docker ps -a --filter "name=jenkins-local\|sonarqube\|postgres"
```

## 🧹 Cleanup

### Stop All Services

```bash
./stop_pipeline.sh
```

### Remove Everything (Full Reset)

```bash
docker stop jenkins-local sonarqube sonarqube-db
docker rm jenkins-local sonarqube sonarqube-db
docker volume rm jenkins_home
docker system prune -a --volumes
```

### Keep Data but Stop Services

```bash
docker stop jenkins-local sonarqube sonarqube-db
```

### Restart After Stopping

```bash
./boot-pipeline.sh
```

## 📝 Log Locations

- **Boot Script Log**: `.pipeline/boot.log`
- **ngrok Log**: `/tmp/ngrok.log`
- **ngrok PID**: `/tmp/ngrok.pid`
- **Jenkins Home**: Docker volume `jenkins_home`
- **SonarQube Data**: Docker volume (named in docker-compose)

## 🛠️ Jenkins Image Details

### Installed Tools

- **Maven**: 3.9.6
- **Node.js**: 20 LTS
- **npm**: 10.8.2+
- **Docker CLI**: 26.1.5+
- **Chromium**: 144+
- **Git**: 2.47+

### Image Build

```bash
# Manual rebuild if needed
docker build -f .pipeline/Dockerfile.jenkins -t jenkins/jenkins:with-tools .

# Verify installation
docker run --rm jenkins/jenkins:with-tools \
  sh -c "echo '=== Tools ===' && mvn -v && node -v && npm -v && docker -v && chromium --version"
```

## 🚀 Pipeline Workflow

### On Push to Feature Branch (e.g., `antigravity`)

1. Environment validation ✓
2. Checkout code ✓
3. Build backend (Maven) ✓
4. Test frontend (Karma + Chromium) ✓
5. SonarQube analysis ✓
6. Quality gate check ✓
7. Parallel tests (backend + frontend) ✓
8. Deploy stage skipped (requires approval on main) ✓

### On Push to Main Branch

1. All above stages +
2. Code review approval gate (requires safezone-reviewers approval)
3. Deploy stage (local Docker deployment)

## 📚 Further Documentation

- **Jenkinsfile**: `.pipeline/Jenkinsfile` - Pipeline stages and steps
- **Docker Compose**: `.pipeline/docker-compose.yml` - Service definitions
- **Validation Script**: `.pipeline/jenkins/validate-environment.sh` - Tool verification
- **Dockerfile**: `.pipeline/Dockerfile.jenkins` - Custom Jenkins image

## 🆘 Getting Help

### Check Boot Script Log

```bash
tail -50 .pipeline/boot.log
```

### Test Individual Tools

```bash
# Inside Jenkins container
docker exec jenkins-local mvn --version
docker exec jenkins-local node --version
docker exec jenkins-local npm --version
docker exec jenkins-local chromium --version
docker exec jenkins-local docker version
```

### Full System Check

```bash
./boot-pipeline.sh --help
# Then run with appropriate options
```

## ✅ Success Indicators

After running `./boot-pipeline.sh`, you should see:

- ✅ Docker daemon running
- ✅ SonarQube ready (http://localhost:9000)
- ✅ Jenkins ready (http://localhost:8088)
- ✅ ngrok tunnel established
- ✅ All in boot.log file

Now you're ready to push code and trigger builds!
