# SonarQube Quick Start - SafeZone

This is a quick reference guide to get SonarQube running and test the integration locally before pushing to Jenkins.

## 1. Start SonarQube (30 seconds)

```bash
cd /Users/othmane.afilali/Desktop/SafeZone/.pipeline
docker-compose up -d sonarqube-db sonarqube
```

**Wait for SonarQube to start** (~2-3 minutes on first run):
```bash
docker logs -f buy01-sonarqube
```

Look for: `SonarQube is operational`

## 2. Access SonarQube Web UI

Open: http://localhost:9000

**Login:**
- Username: `admin`
- Password: `admin`

Change password when prompted (required on first login).

## 3. Generate Token

1. Click profile (top right) → **My Account**
2. Go to **Security** tab
3. Generate Token:
   - Name: `Jenkins Pipeline`
   - Type: `Global Analysis Token`
   - Expires: `No expiration`
4. **Copy the token** (you can't see it again!)

Example: `squ_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0`

## 4. Test Local Analysis

```bash
cd /Users/othmane.afilali/Desktop/SafeZone

# Run tests first (generates coverage)
mvn clean test

# Run SonarQube analysis (replace YOUR_TOKEN with your actual token)
mvn sonar:sonar \
  -Dsonar.projectKey=safezone-ecommerce \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=YOUR_TOKEN_HERE
```

**Expected output:**
```
[INFO] ANALYSIS SUCCESSFUL, you can browse http://localhost:9000/dashboard?id=safezone-ecommerce
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
```

## 5. View Results

Open: http://localhost:9000/dashboard?id=safezone-ecommerce

You'll see:
- **Bugs:** 0 expected (clean project)
- **Vulnerabilities:** Check for any security issues
- **Code Smells:** May have some maintainability issues
- **Coverage:** Depends on your current test coverage
- **Duplications:** Check for duplicate code

## 6. Add Token to Jenkins (Before Pushing)

**Important:** Do this BEFORE pushing to GitHub!

1. Open Jenkins: http://your-jenkins-url:8080
2. Go to **Manage Jenkins** → **Credentials**
3. Click **Add Credentials**
4. Configure:
   - **Kind:** Secret text
   - **Secret:** Paste your SonarQube token
   - **ID:** `sonarqube-token` (MUST match this exactly!)
   - **Description:** SonarQube token for pipeline
5. Click **Create**

### Install SonarQube Scanner Plugin

1. **Manage Jenkins** → **Plugins**
2. Search: "SonarQube Scanner"
3. Install **SonarQube Scanner for Jenkins**
4. Restart Jenkins if needed

### Configure SonarQube Server in Jenkins

1. **Manage Jenkins** → **System**
2. Scroll to **SonarQube servers**
3. Click **Add SonarQube**
4. Configure:
   - **Name:** `SonarQube` (MUST match Jenkinsfile!)
   - **Server URL:** `http://localhost:9000`
   - **Token:** Select `sonarqube-token`
5. **Save**

## 7. Push to GitHub

```bash
git push origin othmane
```

This will trigger Jenkins to:
1. ✅ Build backend
2. ✅ Run tests
3. 🔍 **Run SonarQube analysis**
4. 🚦 **Check quality gate**
5. 🚀 Deploy (only if quality gate passes)

## 8. Check Jenkins Build

Watch the build progress:
- Go to your Jenkins job
- Look for the new stages:
  - **SonarQube Analysis** - Should show "Running SonarQube Code Analysis..."
  - **Quality Gate** - Should show "Checking SonarQube Quality Gate..."

**If quality gate passes:**
```
✅ Quality Gate passed with status: OK
→ Build continues to deployment
```

**If quality gate fails:**
```
❌ Pipeline aborted due to quality gate failure: ERROR
→ Build stops, no deployment
→ Email sent with failure details
```

## 9. Common Issues & Fixes

### SonarQube won't start
```bash
docker-compose down
docker-compose up -d sonarqube-db
sleep 10
docker-compose up -d sonarqube
```

### Jenkins can't connect to SonarQube
- Check SonarQube is running: `docker ps | grep sonarqube`
- Verify token in Jenkins credentials
- Ensure server name is exactly `SonarQube` in Jenkins config

### Quality gate always fails
1. Open SonarQube dashboard
2. Check which conditions are failing
3. Fix the issues (bugs, coverage, etc.)
4. Push again

### Analysis takes too long
- This is normal on first run (builds quality profile)
- Subsequent runs are faster (~5-10 minutes)

## 10. Quick Commands Reference

```bash
# Start SonarQube
cd .pipeline && docker-compose up -d sonarqube sonarqube-db

# Check logs
docker logs -f buy01-sonarqube

# Stop SonarQube
docker-compose stop sonarqube sonarqube-db

# Run local analysis
mvn clean test sonar:sonar -Dsonar.login=YOUR_TOKEN

# View all SonarQube containers
docker ps | grep sonar

# Restart SonarQube
docker-compose restart sonarqube
```

## Next Steps

1. ✅ Review initial analysis results
2. ✅ Fix any critical bugs or vulnerabilities
3. ✅ Customize quality gates if needed
4. ✅ Install SonarLint in VS Code for real-time feedback
5. ✅ Monitor quality trends over time

## SonarLint for VS Code (Bonus)

Get real-time code quality feedback while coding:

```bash
code --install-extension SonarSource.sonarlint-vscode
```

Configure to connect to your SonarQube server for synchronized rules.

---

**Ready to go!** 🚀

Push your code and watch SonarQube analyze it automatically through Jenkins.
