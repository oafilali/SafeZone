# SafeZone Pipeline - Complete Script & Documentation Index

## 📋 Quick Reference

This repository has been fully hardened with comprehensive scripts for infrastructure management, diagnostics, and troubleshooting. All scripts include:

- ✓ Comprehensive error handling
- ✓ Detailed logging for debugging
- ✓ Clear status messages and progress indicators
- ✓ Portable across different computers and operating systems
- ✓ Built-in help documentation
- ✓ Recovery procedures for common issues

---

## 🚀 Getting Started (Quick Start)

```bash
# 1. Fresh setup
./boot-pipeline.sh

# 2. Check everything is working
./pipeline-tools.sh diagnose

# 3. View logs in real-time
tail -f .pipeline/boot.log

# 4. When done, stop gracefully (preserves data)
./stop_pipeline.sh

# 5. Or stop and clean up everything
./stop_pipeline.sh --cleanup
```

---

## 📁 Main Scripts

### 1. **`boot-pipeline.sh`** ⭐ Primary Boot Script

- **Purpose:** Start all pipeline services (Jenkins, SonarQube, PostgreSQL, ngrok)
- **Status:** ✓ Executable, fully enhanced
- **Key Features:**
  - Prerequisite validation (Docker, Compose, disk space)
  - Jenkins image verification and rebuild on demand
  - Comprehensive logging to `.pipeline/boot.log`
  - Command-line options for different scenarios

**Usage:**

```bash
./boot-pipeline.sh                    # Standard boot
./boot-pipeline.sh --cleanup          # Clean start (removes old resources)
./boot-pipeline.sh --rebuild-jenkins  # Force rebuild of Jenkins
./boot-pipeline.sh --no-ngrok         # Local-only (no tunnel)
./boot-pipeline.sh --help             # Show help
```

**Documentation:** See [SCRIPTS_REFERENCE.md](SCRIPTS_REFERENCE.md#1-boot-pipelinesh---infrastructure-bootstrap)

---

### 2. **`stop_pipeline.sh`** ⭐ Primary Shutdown Script

- **Purpose:** Gracefully stop all services
- **Status:** ✓ Executable, fully enhanced
- **Key Features:**
  - Graceful shutdown with configurable timeout
  - Optional cleanup (remove containers and volumes)
  - Force-stop capability
  - Comprehensive logging

**Usage:**

```bash
./stop_pipeline.sh                    # Graceful stop (preserves data)
./stop_pipeline.sh --force            # Force stop (immediate)
./stop_pipeline.sh --cleanup          # Remove all containers and data
./stop_pipeline.sh --help             # Show help
```

**Documentation:** See [SCRIPTS_REFERENCE.md](SCRIPTS_REFERENCE.md#2-stop_pipelinesh---infrastructure-shutdown)

---

### 3. **`pipeline-tools.sh`** ⭐ Diagnostics & Management

- **Purpose:** Diagnose issues, view logs, manage Docker resources
- **Status:** ✓ Executable, fully enhanced
- **Key Features:**
  - Comprehensive system diagnostics
  - Service log viewing
  - Docker resource management
  - Jenkins reset capability

**Usage:**

```bash
./pipeline-tools.sh diagnose           # Full system diagnostics
./pipeline-tools.sh logs jenkins       # View Jenkins logs
./pipeline-tools.sh logs sonarqube     # View SonarQube logs
./pipeline-tools.sh logs postgres      # View database logs
./pipeline-tools.sh disk-info          # Docker disk usage
./pipeline-tools.sh docker-stats       # Real-time container stats
./pipeline-tools.sh cleanup            # Remove unused Docker resources
./pipeline-tools.sh cleanup --force    # Remove without confirmation
./pipeline-tools.sh reset-jenkins      # Complete Jenkins reset
./pipeline-tools.sh help               # Show help
```

**Documentation:** See [SCRIPTS_REFERENCE.md](SCRIPTS_REFERENCE.md#3-pipeline-toolsh---diagnostics--troubleshooting)

---

## 📚 Documentation Files

### **[SETUP_GUIDE.md](SETUP_GUIDE.md)** 📖

Complete setup instructions for fresh installations:

- Prerequisites and system requirements
- Quick start (4 steps)
- Boot script options and examples
- Jenkins and SonarQube configuration
- 8+ troubleshooting scenarios with solutions
- Monitoring and cleanup procedures
- Jenkins image verification

**When to use:** Setting up on a new computer or troubleshooting setup issues

---

### **[SCRIPTS_REFERENCE.md](SCRIPTS_REFERENCE.md)** 📖

Comprehensive reference for all scripts and tools:

- Detailed usage for each script
- All available options and flags
- Examples and workflows
- Log file descriptions and locations
- Error handling and recovery procedures
- Best practices and tips
- Docker Compose services overview

**When to use:** Looking up specific script functionality or troubleshooting

---

### **[SCRIPTS_INDEX.md](SCRIPTS_INDEX.md)** 📖 (This file)

Quick reference index and getting started guide

---

## 🔧 Infrastructure Scripts (Supporting)

### `.pipeline/Dockerfile.jenkins`

- **Purpose:** Define custom Jenkins Docker image with all CI/CD tools
- **Location:** `.pipeline/Dockerfile.jenkins`
- **Status:** ✓ Enhanced with verification and documentation
- **Includes:** Maven, Node.js, npm, Docker CLI, Chromium, Git
- **Build:** Automatic during `boot-pipeline.sh` or use:
  ```bash
  docker build -t jenkins/jenkins:with-tools -f .pipeline/Dockerfile.jenkins .pipeline/
  ```

---

### `.pipeline/jenkins/validate-environment.sh`

- **Purpose:** Validate environment during Jenkins pipeline execution
- **Location:** `.pipeline/jenkins/validate-environment.sh`
- **Status:** ✓ Completely rewritten with comprehensive checks
- **Features:**
  - Multi-category tool checking
  - Chrome/Chromium path detection
  - Exit codes for pipeline integration
  - Detailed error reporting

---

### `.pipeline/Jenkinsfile`

- **Purpose:** Define CI/CD pipeline stages
- **Location:** `.pipeline/Jenkinsfile`
- **Status:** ✓ Enhanced with robust Chrome detection
- **Stages:** Environment validation, backend build, frontend tests, SonarQube, quality gates

---

## 📊 Common Workflows

### Start Fresh Pipeline

```bash
./boot-pipeline.sh --cleanup
# Wait 2-3 minutes for services to start
./pipeline-tools.sh diagnose  # Verify everything
```

### Check System Health

```bash
./pipeline-tools.sh diagnose
# Shows: OS, Docker status, services, tools, disk usage
```

### View Service Logs

```bash
./pipeline-tools.sh logs jenkins
./pipeline-tools.sh logs sonarqube
# Press Ctrl+C to exit
```

### Monitor Resource Usage

```bash
./pipeline-tools.sh docker-stats
# Real-time CPU, memory, I/O usage
# Press Ctrl+C to exit
```

### Free Up Disk Space

```bash
./pipeline-tools.sh cleanup
# Removes unused Docker resources
# or
./stop_pipeline.sh --cleanup
./boot-pipeline.sh
```

### Rebuild Jenkins

```bash
# Option 1: During boot
./boot-pipeline.sh --rebuild-jenkins

# Option 2: Manual reset
./pipeline-tools.sh reset-jenkins
./boot-pipeline.sh
```

### Clean Stop (Preserve Data)

```bash
./stop_pipeline.sh
# All data preserved
./boot-pipeline.sh  # Restart anytime
```

### Complete Cleanup

```bash
./stop_pipeline.sh --cleanup
# All containers and data removed
./boot-pipeline.sh  # Fresh start
```

---

## 🛠️ Troubleshooting Guide

### Problem: Services won't start

```bash
# 1. Check system status
./pipeline-tools.sh diagnose

# 2. View boot log
tail -f .pipeline/boot.log

# 3. Clean start
./stop_pipeline.sh
./boot-pipeline.sh --cleanup
```

### Problem: Chrome not found

```bash
# Rebuild Jenkins with Chromium
./boot-pipeline.sh --rebuild-jenkins
# or
./pipeline-tools.sh reset-jenkins
./boot-pipeline.sh
```

### Problem: Disk full

```bash
# Check usage
./pipeline-tools.sh disk-info

# Free space
./pipeline-tools.sh cleanup
```

### Problem: Docker daemon not responding

```bash
# Check Docker status
docker ps

# If fails, restart Docker (Mac/Linux varies)
# Then:
./stop_pipeline.sh
./boot-pipeline.sh
```

### Problem: Port already in use

```bash
# Find what's using the port
lsof -i :8080   # Jenkins
lsof -i :9000   # SonarQube
lsof -i :5432   # PostgreSQL

# Either: kill the process
# Or: modify docker-compose.yml ports
```

**For more detailed troubleshooting:** See [SETUP_GUIDE.md - Troubleshooting](SETUP_GUIDE.md#troubleshooting)

---

## 📝 Log Files

### `.pipeline/boot.log`

- **Created:** When running `./boot-pipeline.sh`
- **Contains:** Boot progress, prerequisite checks, service startup logs
- **View:** `tail -f .pipeline/boot.log` or `./pipeline-tools.sh logs jenkins`

### `.pipeline/stop.log`

- **Created:** When running `./stop_pipeline.sh`
- **Contains:** Stop progress, cleanup operations
- **View:** `cat .pipeline/stop.log`

### Service Logs (Real-time)

```bash
./pipeline-tools.sh logs jenkins    # Jenkins container
./pipeline-tools.sh logs sonarqube  # SonarQube container
./pipeline-tools.sh logs postgres   # PostgreSQL container
```

---

## ✅ What's Been Fixed & Hardened

### Issues Resolved:

1. ✅ Disk space management (cleanup options added)
2. ✅ Missing tools in Jenkins (image verification added)
3. ✅ Environment validation hanging (timeouts added)
4. ✅ Chrome not found (multi-path detection, Chromium in image)
5. ✅ Hardcoded paths (portable detection added)
6. ✅ Poor error messages (comprehensive logging added)
7. ✅ No recovery procedures (documentation and scripts added)

### Enhancements Made:

1. ✅ Command-line argument parsing for all options
2. ✅ Comprehensive logging to files for debugging
3. ✅ Detailed health checks and validation
4. ✅ Color-coded status messages for clarity
5. ✅ Helper functions for consistent output
6. ✅ Prerequisite checking before execution
7. ✅ Graceful error handling and recovery
8. ✅ Multiple path detection for cross-OS compatibility
9. ✅ Image verification during build
10. ✅ Comprehensive documentation and guides

---

## 🎯 For Different Scenarios

### Setting Up on New Computer

1. **Read:** [SETUP_GUIDE.md](SETUP_GUIDE.md)
2. **Run:** `./boot-pipeline.sh`
3. **Verify:** `./pipeline-tools.sh diagnose`
4. **Reference:** [SCRIPTS_REFERENCE.md](SCRIPTS_REFERENCE.md)

### Troubleshooting Issues

1. **Run:** `./pipeline-tools.sh diagnose`
2. **Check logs:** `./pipeline-tools.sh logs [service]`
3. **Reference:** [SETUP_GUIDE.md - Troubleshooting](SETUP_GUIDE.md#troubleshooting)
4. **Execute fixes:** Use appropriate script options

### Managing Resources

1. **Check usage:** `./pipeline-tools.sh disk-info`
2. **View stats:** `./pipeline-tools.sh docker-stats`
3. **Cleanup:** `./pipeline-tools.sh cleanup`

### Daily Operations

1. **Start:** `./boot-pipeline.sh`
2. **Monitor:** `./pipeline-tools.sh docker-stats`
3. **Check health:** `./pipeline-tools.sh diagnose`
4. **Stop:** `./stop_pipeline.sh`

---

## 📋 Pre-flight Checklist

Before running `boot-pipeline.sh`:

- [ ] Docker is installed (`docker --version`)
- [ ] Docker daemon is running (`docker ps`)
- [ ] Docker Compose is installed (`docker-compose --version`)
- [ ] At least 10GB free disk space (`df -h`)
- [ ] Ports 8080, 9000, 5432 are available
- [ ] Git is installed (`git --version`)
- [ ] ngrok token configured (if using ngrok)

**Automatic Check:**

```bash
./pipeline-tools.sh diagnose
```

---

## 🔍 Script Status Summary

| Script            | Status  | Executable | Enhanced | Documented |
| ----------------- | ------- | ---------- | -------- | ---------- |
| boot-pipeline.sh  | ✓ Ready | ✓ Yes      | ✓ Yes    | ✓ Yes      |
| stop_pipeline.sh  | ✓ Ready | ✓ Yes      | ✓ Yes    | ✓ Yes      |
| pipeline-tools.sh | ✓ Ready | ✓ Yes      | ✓ Yes    | ✓ Yes      |
| start_all.sh      | Legacy  | ✓ Yes      | -        | -          |
| start_docker.sh   | Legacy  | ✓ Yes      | -        | -          |
| stop_all.sh       | Legacy  | ✓ Yes      | -        | -          |

---

## 🚨 Emergency Commands

```bash
# Emergency stop (force)
./stop_pipeline.sh --force

# Emergency clean (remove everything)
./stop_pipeline.sh --cleanup

# Emergency restart
./stop_pipeline.sh && sleep 5 && ./boot-pipeline.sh

# Manual Docker cleanup
docker system prune -a --volumes

# Check what's running
docker ps -a

# View system resources
./pipeline-tools.sh docker-stats
```

---

## 📞 Support & Resources

### Quick Diagnostics

```bash
./pipeline-tools.sh diagnose
```

### Service Logs

```bash
./pipeline-tools.sh logs jenkins
./pipeline-tools.sh logs sonarqube
./pipeline-tools.sh logs postgres
```

### Boot Log

```bash
tail -f .pipeline/boot.log
```

### Documentation

- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Setup and troubleshooting
- [SCRIPTS_REFERENCE.md](SCRIPTS_REFERENCE.md) - Script reference
- [JENKINSFILE_WORKFLOW_DIAGRAM.md](JENKINSFILE_WORKFLOW_DIAGRAM.md) - Pipeline workflow

---

## 🎓 Next Steps

1. **Immediate:** Run `./boot-pipeline.sh` to start services
2. **Then:** Run `./pipeline-tools.sh diagnose` to verify
3. **Next:** Read [SCRIPTS_REFERENCE.md](SCRIPTS_REFERENCE.md) for detailed options
4. **Reference:** Keep [SETUP_GUIDE.md](SETUP_GUIDE.md) handy for troubleshooting

---

## 📊 Summary

**What You Have:**

- ✓ 3 production-ready main scripts (boot, stop, tools)
- ✓ Comprehensive documentation (2 guides + this index)
- ✓ Enhanced infrastructure files (Dockerfile, validation scripts)
- ✓ Logging and diagnostics built-in
- ✓ Error handling and recovery procedures
- ✓ Portable across computers and operating systems

**What's Fixed:**

- ✓ All previous issues resolved
- ✓ Scripts thoroughly hardened
- ✓ Comprehensive error handling
- ✓ Detailed logging for debugging
- ✓ Clear status messages
- ✓ Ready for team distribution

**You Can Now:**

- ✓ Start fresh on any computer
- ✓ Troubleshoot issues with built-in diagnostics
- ✓ Manage resources efficiently
- ✓ View real-time logs and statistics
- ✓ Scale to multiple environments

---

**Version:** 2.0  
**Status:** Production Ready  
**Last Updated:** 2024

For detailed information, see [SCRIPTS_REFERENCE.md](SCRIPTS_REFERENCE.md) and [SETUP_GUIDE.md](SETUP_GUIDE.md).
