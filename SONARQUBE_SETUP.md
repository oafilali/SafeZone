# SonarQube Setup Guide for SafeZone

This guide walks you through setting up SonarQube for continuous code quality monitoring in the SafeZone e-commerce microservices project.

## Overview

SonarQube has been integrated into the SafeZone project with:

- Docker-based SonarQube Community Edition
- PostgreSQL database for persistent storage
- Jenkins CI/CD pipeline integration
- Automated quality gate checks that fail the build on issues

## Prerequisites

- Docker and Docker Compose installed
- Jenkins with the SonarQube Scanner plugin installed
- Maven 3.6+
- Java 17

## Step 1: Start SonarQube

Start SonarQube and its PostgreSQL database:

```bash
cd .pipeline
docker-compose up -d sonarqube sonarqube-db
```

Wait for SonarQube to start (this may take 2-3 minutes on first launch):

```bash
docker logs -f buy01-sonarqube
```

Look for the message: `SonarQube is operational`

## Step 2: Access SonarQube Web Interface

Open your browser and navigate to:

```
http://localhost:9000
```

**Default credentials:**

- Username: `admin`
- Password: `admin`

⚠️ **Important:** You'll be prompted to change the password on first login. Choose a strong password.

## Step 3: Generate Authentication Token

1. Log in to SonarQube
2. Click on your profile (top right) → **My Account**
3. Go to **Security** tab
4. Under **Generate Tokens**:
   - Name: `Jenkins Pipeline`
   - Type: `Global Analysis Token`
   - Expires in: `No expiration` (or set to your preference)
5. Click **Generate**
6. **Copy the token immediately** (you won't be able to see it again)

Example token format: `squ_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0`

## Step 4: Configure Jenkins Credentials

### Add SonarQube Token to Jenkins

1. Open Jenkins → **Manage Jenkins** → **Credentials**
2. Select the appropriate domain (usually `(global)`)
3. Click **Add Credentials**
4. Configure:
   - **Kind:** Secret text
   - **Scope:** Global
   - **Secret:** Paste your SonarQube token
   - **ID:** `sonarqube-token`
   - **Description:** SonarQube authentication token for pipeline
5. Click **Create**

### Install SonarQube Scanner Plugin

1. Go to **Manage Jenkins** → **Plugins**
2. Search for "SonarQube Scanner"
3. Install **SonarQube Scanner for Jenkins** plugin
4. Restart Jenkins if prompted

### Configure SonarQube Server in Jenkins

1. Go to **Manage Jenkins** → **System**
2. Scroll to **SonarQube servers** section
3. Click **Add SonarQube**
4. Configure:
   - **Name:** `SonarQube` (must match the name in Jenkinsfile)
   - **Server URL:** `http://localhost:9000`
   - **Server authentication token:** Select `sonarqube-token` from dropdown
5. Click **Save**

## Step 5: Run Your First Analysis

### Manual Analysis (Local)

Test SonarQube locally before running through Jenkins:

```bash
cd /Users/othmane.afilali/Desktop/SafeZone

# Run tests to generate coverage
mvn clean test

# Run SonarQube analysis
mvn sonar:sonar \
  -Dsonar.projectKey=safezone-ecommerce \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=YOUR_SONARQUBE_TOKEN
```

### Via Jenkins Pipeline

Push your code to GitHub to trigger the Jenkins pipeline:

```bash
git add .
git commit -m "feat: integrate SonarQube for code quality monitoring"
git push origin othmane
```

The Jenkins pipeline will automatically:

1. Build the backend services
2. Run JUnit tests
3. **Run SonarQube analysis**
4. **Check Quality Gate**
5. Deploy (only if Quality Gate passes)

## Step 6: View Analysis Results

1. Open SonarQube: http://localhost:9000
2. Click on your project: **SafeZone E-Commerce Microservices**
3. Review:
   - **Bugs:** Potential runtime errors
   - **Vulnerabilities:** Security issues
   - **Code Smells:** Maintainability issues
   - **Coverage:** Test coverage percentage
   - **Duplications:** Duplicate code blocks
   - **Security Hotspots:** Areas to review for security

## Understanding Quality Gates

The default Quality Gate requires:

- **0 new bugs** on new code
- **0 new vulnerabilities** on new code
- **Code coverage ≥ 80%** on new code
- **Duplications ≤ 3%** on new code
- **Maintainability Rating = A** on new code

If any condition fails, the Jenkins pipeline will **fail** and deployment will not proceed.

### Customizing Quality Gates

1. In SonarQube, go to **Quality Gates**
2. Either modify the default or create a custom gate
3. Set your own thresholds for:
   - Coverage
   - Duplications
   - Maintainability Rating
   - Reliability Rating
   - Security Rating

## Pipeline Behavior

### When Quality Gate Passes ✅

```
✅ Quality Gate passed with status: OK
→ Pipeline continues to deployment
```

### When Quality Gate Fails ❌

```
❌ Pipeline aborted due to quality gate failure: ERROR
→ Deployment is blocked
→ Email notification sent
→ Fix issues and push again
```

### Skipping SonarQube Analysis

You can skip SonarQube analysis by using the Jenkins build parameter:

- **SKIP_TESTS:** `true` (this also skips JUnit and Karma tests)

## Troubleshooting

### SonarQube won't start

Check logs:

```bash
docker logs buy01-sonarqube
```

Common issues:

- Insufficient memory (SonarQube needs at least 2GB RAM)
- Database connection issues

Solution:

```bash
docker-compose down
docker-compose up -d sonarqube-db
# Wait 10 seconds
docker-compose up -d sonarqube
```

### Quality Gate always fails

Check the specific failures in SonarQube:

1. Open the project in SonarQube
2. Go to **Quality Gate** tab
3. Review which conditions are failing
4. Click on failing metrics to see details

### Jenkins can't connect to SonarQube

Verify:

1. SonarQube is running: `docker ps | grep sonarqube`
2. Token is correct in Jenkins credentials
3. SonarQube server configuration in Jenkins matches Jenkinsfile
4. Jenkins can reach `http://localhost:9000`

## Bonus Features

### Email Notifications with SonarQube Results

Email templates already include placeholders for SonarQube results. When quality issues are detected, developers receive detailed reports.

### IDE Integration

Install SonarLint in your IDE for real-time feedback:

**VS Code:**

```bash
code --install-extension SonarSource.sonarlint-vscode
```

**IntelliJ IDEA:**

- Go to **Plugins** → Search "SonarLint" → Install

Configure SonarLint to connect to your local SonarQube:

1. Open SonarLint settings
2. Add connection: `http://localhost:9000`
3. Use your token for authentication

### Continuous Monitoring

SonarQube runs automatically on every push to GitHub via Jenkins webhooks. No manual intervention needed!

## Project Structure

```
.pipeline/
├── docker-compose.yml          # Includes SonarQube + PostgreSQL
├── Jenkinsfile                  # Pipeline with SonarQube stages
└── jenkins/
    ├── email-success.html       # Email template
    ├── email-failure.html       # Email template
    └── ...

pom.xml                          # Parent POM with SonarQube plugin
├── <properties>
│   └── sonar.* configuration
└── <plugins>
    ├── jacoco-maven-plugin      # Code coverage
    └── sonar-maven-plugin       # SonarQube analysis
```

## Next Steps

1. ✅ Review your first SonarQube analysis results
2. ✅ Fix any critical bugs or vulnerabilities
3. ✅ Customize quality gates to match your team's standards
4. ✅ Install SonarLint in your IDE
5. ✅ Set up Slack/email notifications (bonus)
6. ✅ Document code review process with SonarQube

## Resources

- [SonarQube Documentation](https://docs.sonarqube.org/latest/)
- [SonarQube Jenkins Plugin](https://docs.sonarqube.org/latest/analysis/scan/sonarscanner-for-jenkins/)
- [Quality Gates](https://docs.sonarqube.org/latest/user-guide/quality-gates/)
- [SonarLint](https://www.sonarlint.org/)

## Support

For issues or questions:

1. Check SonarQube logs: `docker logs buy01-sonarqube`
2. Check Jenkins console output for pipeline failures
3. Review this guide's Troubleshooting section
4. Consult SonarQube documentation

---

**Status:** ✅ Fully Configured
**Last Updated:** January 12, 2026
**Project:** SafeZone E-Commerce Microservices
