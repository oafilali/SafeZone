# Pipeline Scripts Reference

This document provides a comprehensive guide to all the infrastructure scripts in this project.

## Overview

The SafeZone pipeline infrastructure consists of multiple shell scripts designed to automate deployment, management, and troubleshooting. Each script serves a specific purpose and includes comprehensive error handling, logging, and help documentation.

---

## Main Scripts

### 1. `boot-pipeline.sh` - Infrastructure Bootstrap

**Purpose:** Start all pipeline services (Jenkins, SonarQube, PostgreSQL, ngrok)

**Location:** `/boot-pipeline.sh` (root directory)

**Usage:**

```bash
./boot-pipeline.sh [OPTIONS]
```

**Options:**

- `--cleanup` - Remove Docker resources before starting (cleans up old containers/images)
- `--rebuild-jenkins` - Force rebuild of custom Jenkins image
- `--no-ngrok` - Start pipeline without ngrok tunnel (local only)
- `--help` - Display help information

**Examples:**

```bash
# Standard startup
./boot-pipeline.sh

# Clean start (removes old containers/images)
./boot-pipeline.sh --cleanup

# Rebuild Jenkins image and start
./boot-pipeline.sh --rebuild-jenkins

# Local-only setup (no ngrok tunnel)
./boot-pipeline.sh --no-ngrok

# Complete fresh start
./boot-pipeline.sh --cleanup --rebuild-jenkins
```

**What It Does:**

1. ✓ Validates prerequisites (Docker, Docker Compose, disk space)
2. ✓ Builds custom Jenkins image with Maven, Node.js, npm, Docker CLI, Chromium
3. ✓ Starts SonarQube with PostgreSQL database
4. ✓ Starts Jenkins master
5. ✓ Establishes ngrok tunnel (unless `--no-ngrok` specified)
6. ✓ Verifies all services are running
7. ✓ Logs all operations to `.pipeline/boot.log`

**Logs:** `.pipeline/boot.log`

**Success Indicators:**

- All services show "Running" or "OK"
- Jenkins is accessible at the provided URL
- SonarQube is accessible at http://localhost:9000
- ngrok tunnel URL is displayed

**Troubleshooting:**

- Check `.pipeline/boot.log` for detailed error messages
- Run `./pipeline-tools.sh diagnose` to check system status
- Run `./stop_pipeline.sh` then `./boot-pipeline.sh` for clean restart

---

### 2. `stop_pipeline.sh` - Infrastructure Shutdown

**Purpose:** Gracefully stop all pipeline services

**Location:** `/stop_pipeline.sh` (root directory)

**Usage:**

```bash
./stop_pipeline.sh [OPTIONS]
```

**Options:**

- `--force` - Force stop containers (no graceful shutdown)
- `--cleanup` - Remove containers and volumes (deletes all data)
- `--help` - Display help information

**Examples:**

```bash
# Graceful shutdown (preserves data)
./stop_pipeline.sh

# Force stop (immediate)
./stop_pipeline.sh --force

# Complete cleanup (removes all containers and data)
./stop_pipeline.sh --cleanup

# Force stop and cleanup
./stop_pipeline.sh --force --cleanup
```

**What It Does:**

1. ✓ Stops ngrok tunnel
2. ✓ Gracefully stops all containers (Jenkins, SonarQube, PostgreSQL)
3. ✓ Optionally removes containers and volumes (with `--cleanup`)
4. ✓ Logs all operations to `.pipeline/stop.log`

**Logs:** `.pipeline/stop.log`

**Data Preservation:**

- By default, `stop_pipeline.sh` preserves all data
- Volumes remain intact and can be restarted
- Use `--cleanup` flag only when you want to reset everything

**Restart After Stop:**

```bash
# If you used stop without --cleanup, just run:
./boot-pipeline.sh

# If you used --cleanup, everything will be recreated fresh:
./boot-pipeline.sh
```

---

### 3. `pipeline-tools.sh` - Diagnostics & Troubleshooting

**Purpose:** Diagnose issues, view logs, manage resources, and troubleshoot problems

**Location:** `/pipeline-tools.sh` (root directory)

**Usage:**

```bash
./pipeline-tools.sh [COMMAND] [OPTIONS]
```

**Commands:**

#### 3.1 Diagnostics

```bash
./pipeline-tools.sh diagnose
```

Runs comprehensive system diagnostics including:

- OS and system information
- Docker installation and daemon status
- Docker Compose version
- Pipeline service status (Jenkins, SonarQube, PostgreSQL)
- Required tools status (git, Maven, Node, npm)
- Disk usage

**Output Example:**

```
System Information
  OS: Linux/Darwin
  Architecture: x86_64
  Kernel: 20.6.0

Docker Status
  Docker: Docker version 26.1.5
  Status: Running

Pipeline Services
  ✓ jenkins-local: Running (running)
  ✓ sonarqube: Running (running)
  ✓ sonarqube-db: Running (running)

Required Tools
  ✓ git: Installed
  ✓ mvn: Installed (Apache Maven 3.9.6)
  ✓ node: Installed (v20.0.0)
  ✓ npm: Installed (10.8.2)
```

#### 3.2 Logs

```bash
./pipeline-tools.sh logs [SERVICE]
```

Display logs for a specific service (last 100 lines, with real-time updates):

**Available Services:**

- `jenkins` - Jenkins master container logs
- `sonarqube` - SonarQube container logs
- `postgres` or `db` - PostgreSQL database logs

**Examples:**

```bash
./pipeline-tools.sh logs jenkins
./pipeline-tools.sh logs sonarqube
./pipeline-tools.sh logs postgres
```

**Usage Tips:**

- Press `Ctrl+C` to exit log streaming
- Logs are continuously updated (like `tail -f`)
- Shows last 100 lines before streaming starts

#### 3.3 Disk Usage

```bash
./pipeline-tools.sh disk-info
```

Detailed Docker disk usage breakdown:

- Total images, containers, volumes usage
- Top 10 images by size
- Top 10 containers by size
- Volume list with mount points

**Useful for:** Identifying what's consuming disk space

#### 3.4 Real-time Statistics

```bash
./pipeline-tools.sh docker-stats
```

Real-time Docker container statistics:

- CPU usage percentage
- Memory usage
- Network I/O
- Process count

**Usage Tips:**

- Shows snapshot first, then continuous monitoring
- Press `Ctrl+C` to exit
- Useful for identifying performance issues

#### 3.5 Cleanup

```bash
./pipeline-tools.sh cleanup [--force]
```

Remove unused Docker resources (images, containers, volumes):

- Dangling images
- Stopped containers
- Unused volumes
- Build cache

**Examples:**

```bash
./pipeline-tools.sh cleanup
# Prompts: "Continue? (y/n)" - Type 'y' to confirm

./pipeline-tools.sh cleanup --force
# Skips confirmation, proceeds immediately
```

**Safety:** Only removes unused resources, not active containers

#### 3.6 Jenkins Reset

```bash
./pipeline-tools.sh reset-jenkins
```

Complete Jenkins reset:

1. Stops Jenkins container
2. Removes container and volume
3. Rebuilds Jenkins image from Dockerfile
4. Ready to recreate with `boot-pipeline.sh`

**When to Use:**

- After major issues with Jenkins
- To test that Dockerfile builds correctly
- To clear all Jenkins configuration and start fresh

**Example Workflow:**

```bash
./pipeline-tools.sh reset-jenkins
# ... answers prompts ...
# Jenkins image is rebuilt
./boot-pipeline.sh
# Jenkins restarts with fresh configuration
```

---

## Supporting Scripts

### `start_all.sh`

**Legacy script** - For backward compatibility. Use `boot-pipeline.sh` instead.

### `start_docker.sh`

**Legacy script** - For backward compatibility. Use `boot-pipeline.sh` instead.

### `stop_all.sh`

**Legacy script** - For backward compatibility. Use `stop_pipeline.sh` instead.

---

## Infrastructure Scripts (Jenkins)

### `.pipeline/Dockerfile.jenkins`

Custom Jenkins Docker image configuration with:

- Maven 3.9.6
- Node.js v20
- npm v10.8.2
- Docker CLI v26.1.5
- Chromium 144+ (for headless tests)
- Git
- System fonts for headless rendering

**Build Command:**

```bash
docker build -t jenkins/jenkins:with-tools -f .pipeline/Dockerfile.jenkins .pipeline/
```

**Verification During Build:**
The Dockerfile automatically verifies all tools during build:

```
mvn version 3.9.6
node version v20.x.x
npm version 10.8.x
docker version 26.1.5
chromium version 144.x.x
```

### `.pipeline/jenkins/validate-environment.sh`

Environment validation script run at start of Jenkins pipeline:

- Checks required tools (Maven, Node, npm)
- Validates Docker connectivity
- Verifies Chrome/Chromium for tests
- Exit codes: 0=success, 1=failure, 2=warning

**Categorizes Tools:**

- REQUIRED: Maven, Node, npm, Docker
- SUPPORTING: Chrome/Chromium, Git
- OPTIONAL: Additional tools

---

## Log Files

### Boot Logs

**Location:** `.pipeline/boot.log`

**Contains:**

- Timestamp for each operation
- Prerequisite check results
- Image build progress
- Container start logs
- ngrok tunnel setup
- Service health checks

**View:**

```bash
tail -f .pipeline/boot.log
```

### Stop Logs

**Location:** `.pipeline/stop.log`

**Contains:**

- Timestamp for each operation
- Service stop results
- Cleanup operations (if used)
- Data preservation confirmation

**View:**

```bash
cat .pipeline/stop.log
```

### Jenkins Logs

**Access via Docker:**

```bash
docker logs jenkins-local
docker logs -f jenkins-local  # Real-time
docker logs --tail 100 jenkins-local  # Last 100 lines
```

**Or via Pipeline Tools:**

```bash
./pipeline-tools.sh logs jenkins
```

### SonarQube Logs

**Access via Docker:**

```bash
docker logs sonarqube
docker logs -f sonarqube  # Real-time
```

**Or via Pipeline Tools:**

```bash
./pipeline-tools.sh logs sonarqube
```

---

## Common Workflows

### Fresh Start

```bash
# 1. Clean up any old resources
./boot-pipeline.sh --cleanup

# 2. Wait for services to start (2-3 minutes)
# 3. Access Jenkins at provided URL
# 4. Jenkins configuration happens automatically
```

### Restart After Maintenance

```bash
# Stop gracefully (preserves data)
./stop_pipeline.sh

# Start again
./boot-pipeline.sh

# All previous configurations preserved
```

### Complete Reset

```bash
# Stop and remove everything
./stop_pipeline.sh --cleanup

# Start fresh (all configuration lost)
./boot-pipeline.sh

# System rebuilds from scratch
```

### Troubleshooting Issues

```bash
# 1. Diagnose the system
./pipeline-tools.sh diagnose

# 2. Check service logs
./pipeline-tools.sh logs jenkins
./pipeline-tools.sh logs sonarqube

# 3. Review boot log
tail -f .pipeline/boot.log

# 4. If major issues, reset Jenkins
./pipeline-tools.sh reset-jenkins
```

### Rebuilding Jenkins

```bash
# Method 1: During boot
./boot-pipeline.sh --rebuild-jenkins

# Method 2: Manual reset
./pipeline-tools.sh reset-jenkins
```

---

## Environment Variables

Scripts use these environment variables (set automatically):

- `PROJECT_ROOT` - Root directory of the project
- `LOG_FILE` - Path to current operation log
- `DOCKER_BUILDKIT` - Enabled by default (faster builds)
- `DOCKER_REPO` - Internal Docker registry (if used)

---

## Error Handling & Recovery

### Common Issues & Solutions

**"No space left on device"**

```bash
./pipeline-tools.sh cleanup
# Or
./stop_pipeline.sh --cleanup
docker system prune -a --volumes
```

**"Docker daemon not responding"**

```bash
# Restart Docker daemon (Mac/Linux)
docker ps  # Should work now

# If still fails:
killall Docker  # Mac
systemctl restart docker  # Linux
```

**"Chrome/Chromium not found"**

```bash
# Rebuild Jenkins image
./boot-pipeline.sh --rebuild-jenkins

# Or reset and rebuild
./pipeline-tools.sh reset-jenkins
./boot-pipeline.sh
```

**"Port already in use"**

```bash
# Find what's using the port
lsof -i :8080  # Jenkins
lsof -i :9000  # SonarQube
lsof -i :5432  # PostgreSQL

# Kill the process or change port in docker-compose.yml
```

**Jenkins stuck or not responding**

```bash
# Restart Jenkins
./stop_pipeline.sh
./boot-pipeline.sh

# Or do a full reset
./pipeline-tools.sh reset-jenkins
./boot-pipeline.sh
```

---

## Best Practices

1. **Always use `boot-pipeline.sh` and `stop_pipeline.sh`** - Don't manually stop Docker containers
2. **Check logs first** - Most issues are documented in `.pipeline/boot.log` or service logs
3. **Use `--cleanup` sparingly** - Only when starting completely fresh
4. **Backup before cleanup** - If you have important Jenkins jobs, export them first
5. **Monitor disk space** - Run `./pipeline-tools.sh diagnose` regularly
6. **Use `pipeline-tools.sh` for troubleshooting** - It's specifically designed for diagnostics

---

## Script Dependencies

```
boot-pipeline.sh
├── Requires: Docker, Docker Compose, git
├── Uses: .pipeline/docker-compose.yml
└── Calls: .pipeline/Dockerfile.jenkins
           .pipeline/jenkins/validate-environment.sh

stop_pipeline.sh
├── Requires: Docker
└── Stops: Jenkins, SonarQube, PostgreSQL

pipeline-tools.sh
├── Requires: Docker
├── Provides: diagnose, cleanup, logs, disk-info, docker-stats, reset-jenkins
└── Calls: docker commands internally
```

---

## Docker Compose Services

The `boot-pipeline.sh` script starts services defined in:

**Location:** `.pipeline/docker-compose.yml`

**Services:**

1. **PostgreSQL (sonarqube-db)** - Database for SonarQube
2. **SonarQube** - Code quality analysis
3. **Jenkins** - CI/CD orchestration

**Volumes:**

- `jenkins_home` - Jenkins configuration and job data
- `sonarqube_data` - SonarQube database and analysis results
- `sonarqube_extensions` - SonarQube plugins

---

## For New Team Members

1. **Clone the repository**
2. **Read [SETUP_GUIDE.md](SETUP_GUIDE.md)** for environment setup
3. **Run `./boot-pipeline.sh`** to start the infrastructure
4. **Run `./pipeline-tools.sh diagnose`** to verify everything
5. **Check [SCRIPTS_REFERENCE.md](SCRIPTS_REFERENCE.md)** (this file) for script details
6. **Keep `.pipeline/boot.log` open** while services start to monitor progress

---

## Support & Troubleshooting

For detailed setup instructions, see: [SETUP_GUIDE.md](SETUP_GUIDE.md)

For pipeline workflow and architecture, see: [JENKINSFILE_WORKFLOW_DIAGRAM.md](JENKINSFILE_WORKFLOW_DIAGRAM.md)

For detailed diagnostics, run:

```bash
./pipeline-tools.sh diagnose
```

For specific service issues, check logs:

```bash
./pipeline-tools.sh logs jenkins
./pipeline-tools.sh logs sonarqube
./pipeline-tools.sh logs postgres
```

---

**Last Updated:** 2024
**Version:** 2.0
**Status:** Production Ready
