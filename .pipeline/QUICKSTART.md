# 🚀 SafeZone Local Pipeline - Quick Start

## One-Command Setup

```bash
cd /Users/othmane.afilali/Desktop/antigravity/SafeZone/.pipeline && ./setup-all-local.sh
```

This installs everything: Jenkins, SonarQube, ngrok, and all dependencies.

---

## After Setup - Complete These Steps

### 1. Jenkins Initial Setup (5 min)
1. Open http://localhost:8080
2. Get password: `cat /opt/homebrew/var/jenkins_home/secrets/initialAdminPassword`
3. Install suggested plugins
4. Create admin user

### 2. Configure Jenkins (5 min)
```bash
./setup-local-jenkins.sh
```
Enter your Jenkins credentials when prompted.

### 3. Update Jenkins Credentials (10 min)

**SonarQube Token:**
1. Open http://localhost:9000 (login: admin/admin)
2. Change password
3. My Account → Security → Generate Token
4. Copy token
5. Jenkins → Credentials → Update `sonarqube-token`

**GitHub Token:**
1. https://github.com/settings/tokens
2. Generate new token (classic)
3. Select: `repo` + `admin:repo_hook`
4. Copy token
5. Jenkins → Credentials → Update `github-token`

### 4. Update Jenkinsfile (5 min)
Follow instructions in [JENKINSFILE-UPDATES.md](JENKINSFILE-UPDATES.md)

### 5. Configure GitHub Webhook (2 min)
1. Get ngrok URL: `curl -s http://localhost:4040/api/tunnels | grep -Eo 'https://[^"]+\.ngrok-free\.app'`
2. GitHub → Repo → Settings → Webhooks → Add webhook
3. Payload URL: `https://YOUR-NGROK-URL.ngrok-free.app/github-webhook/`
4. Content type: `application/json`
5. Events: Just the push event

### 6. Test Pipeline (2 min)
```bash
cd /Users/othmane.afilali/Desktop/antigravity/SafeZone
git checkout -b test-pipeline
echo "# Test" >> README.md
git add README.md
git commit -m "Test pipeline"
git push origin test-pipeline
```

Watch the build at http://localhost:8080

---

## Service URLs

| Service | URL | Login |
|---------|-----|-------|
| Jenkins | http://localhost:8080 | Your admin user |
| SonarQube | http://localhost:9000 | admin/admin (change on first login) |
| ngrok Dashboard | http://localhost:4040 | - |
| Application (after build) | http://localhost:4200 | - |

---

## Common Commands

```bash
# Start all services
brew services start jenkins-lts
./setup-sonarqube.sh
./setup-jenkins-webhooks.sh

# Stop all services
brew services stop jenkins-lts
docker-compose stop
pkill -f ngrok

# View logs
tail -f /opt/homebrew/var/log/jenkins-lts/jenkins-lts.log  # Jenkins
docker logs -f buy01-sonarqube  # SonarQube
cat .ngrok-jenkins.log  # ngrok

# Check service status
brew services list | grep jenkins
docker ps | grep -E "sonarqube|buy-01"
pgrep -f ngrok
```

---

## Troubleshooting

| Problem | Quick Fix |
|---------|-----------|
| Jenkins won't start | `brew services restart jenkins-lts` |
| Port 8080 busy | `lsof -i :8080` then kill the process |
| Sonar Qube unhealthy | Wait 2-3 min for first start, or check: `docker logs buy01-sonarqube` |
| ngrok tunnel down | `./setup-jenkins-webhooks.sh` |
| Build fails | Check Jenkins credentials are updated |

For detailed troubleshooting: see [README-local-pipeline.md](README-local-pipeline.md)

---

## Help & Documentation

- **Complete Guide**: [README-local-pipeline.md](README-local-pipeline.md)
- **Jenkinsfile Updates**: [JENKINSFILE-UPDATES.md](JENKINSFILE-UPDATES.md)
- **Architecture & Walkthrough**: See artifacts directory

---

**Need help?** Check the documentation or logs first. Most issues are credential or service startup related.
