# safe-zone

**Production-ready CI/CD pipeline with automated testing, deployment, and zero-downtime rollback capability.**

[![Build Status](http://13.62.141.159:8080/job/SonarQube-buy01-pipeline/badge/icon)](http://13.62.141.159:8080/job/SonarQube-buy01-pipeline/)
![Security](https://img.shields.io/badge/security-100%25-success)
![Tests](https://img.shields.io/badge/tests-passing-success)

> ✅ **Docker socket permissions fixed** - Jenkins can now build and deploy Docker images without permission errors----

## 🎯 Quick Start

1. **Jenkins configured** with required credentials (see [Jenkins Credentials Required](#jenkins-credentials-required))
2. **Push code** → Automatic build & deploy via ngrok webhook
3. **Access app**: http://localhost:4200 (Frontend) | http://localhost:8080 (API Gateway)

---

## 📋 Overview

This project sets up a robust **Continuous Integration and Continuous Deployment (CI/CD)** pipeline using **Jenkins** for the e-commerce platform. The pipeline automatically **builds**, **tests**, and **deploys** your application, ensuring consistent and reliable delivery.

**Your role**: DevOps Engineer - Automating the development workflow with a bulletproof CI/CD system.

## ✅ CI/CD Pipeline Features

### Automated Build Triggers

- ✅ **GitHub Webhook Integration** - Automatic builds on every commit push
- ✅ **Build Status Notifications** - Email alerts with detailed results
- ✅ **Environment Validation** - Checks for required tools (Maven, Node.js, Docker, etc.)

### Testing & Reporting

- ✅ **Backend Testing** - Maven + JUnit test execution with SureFire reports
- ✅ **Frontend Testing** - Karma + Jasmine test runner for Angular
- ✅ **Test Reporting** - JUnit XML parsing and artifact archiving
- ✅ **Coverage Reports** - JaCoCo coverage metrics (when applicable)

### Deployment & Fallback

- ✅ **AWS Deployment** - Primary deployment target (SSH-based)
- ✅ **Docker Fallback** - Automatic Docker deployment if AWS fails
- ✅ **Health Checks** - Verifies deployment success before cleanup
- ✅ **Rollback Strategy** - Automatic rollback on deployment failure

### Notifications & Visibility

- ✅ **Email Notifications** - HTML-formatted status emails with direct links to:
  - Test results dashboard
  - Test artifacts
  - Build logs
  - Coverage reports
- ✅ **Multi-Status Alerts** - Success, Failure, and Unstable build emails
- ✅ **Build Information** - Job name, build number, duration, Git branch

## 🔧 Jenkins Setup & Configuration

### Prerequisites

- **Jenkins** (LTS version) running and accessible
- **GitHub Account** with access to your repository
- **SMTP Server** configured for email notifications (e.g., Gmail with app password)
- **Docker** and **docker-compose** for deployment fallback
- **Maven 3.6+** and **Node.js 18+** for builds

### Step 1: Configure GitHub Credentials in Jenkins

1. Go to **Manage Jenkins** → **Manage Credentials**
2. Click **System** → **Global credentials** → **Add Credentials**
3. Create a **Username with password** credential:
   - **Username**: Your GitHub username
   - **Password**: [GitHub Personal Access Token](https://github.com/settings/tokens)
     - Scopes needed: `repo` and `admin:repo_hook`
   - **ID**: `github-credentials`
4. **Create** and verify connection

### Step 2: Set Up GitHub Webhook for Automatic Builds

1. In your GitHub repository → **Settings** → **Webhooks** → **Add webhook**
2. Configure:
   - **Payload URL**: `http://your-jenkins-url:8090/github-webhook/` (with trailing slash)
   - **Content type**: `application/json`
   - **Events**: Select "Just the push event"
   - **Active**: ✓ Check this box
3. **Add webhook**

**For localhost Jenkins**, use [ngrok](https://ngrok.com/) to expose Jenkins:

```bash
brew install ngrok
ngrok http 8090
# Use the https:// URL provided as your Payload URL
```

### Step 3: Configure Email Notifications

1. **Manage Jenkins** → **System**
2. Scroll to **E-mail Notification** section at the bottom:
   - **SMTP server**: `smtp.gmail.com`
   - **SMTP port**: `465` (Use SSL)
3. Click **Advanced...**
4. Check ☑️ **Use SMTP Authentication**
   - **Username**: Your Gmail address
   - **Password**: [Gmail App Password](https://support.google.com/accounts/answer/185833) (16-character code)
   - **Use SSL**: ✓ Check this box
5. **System Admin e-mail address** (under Jenkins Location): Set to your Gmail address.
6. **Test configuration** and **Save**

### Step 4: Configure Jenkins Job

1. Create a new **Pipeline** job (or copy an existing one)
2. **Pipeline** section → **Definition**: Select "Pipeline script from SCM"
3. **SCM**: Select **Git**
   - **Repository URL**: `https://github.com/jeeeeedi/mr-jenk.git`
   - **Credentials**: Select the GitHub credentials you created
   - **Branch**: `*/cleanup` (or your working branch)
4. **Script Path**: `Jenkinsfile` (default)
5. Under **Build Triggers** → Check ☑️ **GitHub hook trigger for GITScm polling**
6. **Save**

### Step 5: Trigger Your First Build

Simply push code to trigger an automatic build:

```bash
git add .
git commit -m "Test Jenkins webhook"
git push origin cleanup
```

Jenkins will automatically start a build within a few seconds!

### Accessing Build Reports

After a successful build:

1. **Jenkins UI** → Your job → Build #N
2. **Test Results**: Shows parsed JUnit test results
3. **Artifacts**: Download archived test reports and coverage files
4. **Email Notification**: Check your inbox for HTML report with direct links

## 📊 Pipeline Structure

The `Jenkinsfile` defines a multi-stage pipeline with the following flow:

### Pipeline Stages

The pipeline uses a **unified flow** with intelligent decision gates:

```
1. Initialize
   └─ Log context (PR, Main Branch, or Feature Branch)

2. Validate Environment
   ├─ Check Maven, Node.js, npm, Docker, docker-compose, Git, Chrome
   └─ Fail if required tools missing

3. Checkout
   └─ Clone repository from GitHub

4. Build Backend
   ├─ Compile all Spring Boot microservices (mvn clean install)
   └─ Package JAR artifacts

5. Test Frontend (unless SKIP_TESTS=true)
   └─ Run Karma + Jasmine tests for Angular

6. SonarQube Analysis (unless SKIP_TESTS=true)
   ├─ Backend code quality & security scan
   └─ Frontend code quality & security scan

7. Quality Gate Check (unless SKIP_TESTS=true)
   └─ Verify SonarQube quality gate passed (supports multi-branch analysis)

8. Parallel Stages
   ├─ Backend Tests: Execute JUnit tests with SureFire reports
   └─ Frontend Dependencies: npm install with legacy peer deps

9. Post-Build Actions (Always Runs)
   ├─ Archive test reports & coverage
   └─ Email notification (success/failure/unstable)

10. DECISION: Is Main Branch? (IS_MAIN_BRANCH)
    ├─ NO (PR or Feature Branch)
    │  └─ Build Complete - NO DEPLOYMENT
    │     └─ End pipeline
    │
    └─ YES (Main branch post-merge)
       └─ Continue to approval gate

11. DECISION: Code Review Required? (REQUIRE_CODE_REVIEW parameter)
    ├─ NO
    │  └─ Skip to Deploy
    │
    └─ YES
       └─ CODE REVIEW APPROVAL GATE ⏸️ (BLOCKS HERE)
          ├─ Timeout: 24 hours
          ├─ Approved: Continue to Deploy
          └─ Rejected/Timeout: Pipeline fails

12. Deploy (Main branch only)
    ├─ Local Docker: docker-compose up
    ├─ AWS: SSH deploy to EC2 with SSL certs
    └─ Both: Deploy to both simultaneously

13. Publish Reports & Send Notification
    └─ Final email with build status
```

### Pipeline Decision Flow

**All branches (PR, Feature, Main) execute stages 1-9 identically.**

The pipeline diverges ONLY after post-build:

| Context                      | Behavior                  | Approval Gate                         | Deployment           |
| ---------------------------- | ------------------------- | ------------------------------------- | -------------------- |
| **Pull Request**             | Tests run on PR code      | ✅ GitHub PR approval                 | ❌ NO                |
| **Feature Branch**           | Tests run on feature code | ❌ None                               | ❌ NO                |
| **Main Branch** (post-merge) | Tests run on merged code  | ✅ Jenkins Approval Gate (if enabled) | ✅ YES (if approved) |

### Dual Approval Strategy

The pipeline implements **two approval layers** for production deployments:

#### 1️⃣ GitHub PR Approval (BEFORE Merge)

- Enforced by GitHub branch protection rules
- Requires configurable number of approvals (default: 2)
- All Jenkins status checks must pass
- **When**: Developer creates/updates PR
- **Who**: Code reviewers
- **Purpose**: Ensure code quality and standards

#### 2️⃣ Jenkins Approval Gate (AFTER Merge)

- Implemented via `input()` block in Jenkinsfile
- **Only triggered** if `REQUIRE_CODE_REVIEW=true` parameter AND on main branch
- Timeout: 24 hours
- **When**: After successful post-merge testing
- **Who**: DevOps/Release manager from `safezone-reviewers` group
- **Purpose**: Final approval before production deployment

### Why Re-Test After Merge?

Post-merge testing catches issues that didn't exist in the isolated PR:

```
Scenario: Two PRs merged sequentially

PR-A (Dependency X v1.0)
  ├─ Tests pass ✓
  └─ Merged to main

PR-B (Dependency X v2.0)
  ├─ Tests pass in isolation ✓
  ├─ Merged to main
  └─ Merge conflict: X v2.0 breaks compatibility

Post-Merge Test on main:
  └─ Tests fail ✗ (X v2.0 incompatibility caught!)
  └─ Deployment blocked ✅
```

### Pipeline Parameters

You can control pipeline behavior when triggering manually:

| Parameter                | Type    | Default   | Effect                                                  |
| ------------------------ | ------- | --------- | ------------------------------------------------------- |
| `DEPLOYMENT_TARGET`      | choice  | AWS       | Where to deploy: `Local Docker`, `AWS`, or `Both`       |
| `SKIP_TESTS`             | boolean | false     | Skip test stages (not recommended)                      |
| `SKIP_FRONTEND_BUILD`    | boolean | false     | Skip frontend build (backend changes only)              |
| `FORCE_REBUILD`          | boolean | false     | Force clean rebuild (ignore cache)                      |
| `CUSTOM_TAG`             | string  | (empty)   | Custom Docker tag (defaults to build number)            |
| `SONARQUBE_URL_OVERRIDE` | string  | ngrok URL | Override SonarQube URL (for remote Jenkins)             |
| `SONAR_TOKEN_OVERRIDE`   | string  | (empty)   | Override SonarQube token                                |
| `REQUIRE_CODE_REVIEW`    | boolean | true      | Require Jenkins approval gate before deploy (main only) |

### Pipeline Execution Timeline

**Typical execution times:**

```
All Branches (Stages 1-9):  ~90 minutes
├─ Initialize:               1 min
├─ Validate Environment:     2 min
├─ Checkout:                 3 min
├─ Build Backend:           30 min
├─ Test Frontend:           15 min
├─ SonarQube Analysis:      10 min
├─ Quality Gate:             5 min
├─ Parallel Tests:          20 min
└─ Post Actions:             5 min

Main Branch Only (if approved):
├─ Code Review Gate:    Variable (user-dependent, max 24h)
├─ Deploy:              5-60 min (depends on target)
└─ Email:               1 min

Total for Main: 90 minutes + approval time + deployment time
```

### Real-World Scenarios

**Scenario 1: Feature Branch Push**

```
$ git push origin feature-x
  ↓
Jenkins builds & tests
  ↓
Tests pass ✓
  ↓
Email notification: "Build #54 PASSED"
  ↓
No deployment (feature branch)
```

**Scenario 2: PR Merge (REQUIRE_CODE_REVIEW=true)**

```
$ (PR gets 2+ approvals)
$ (Click "Merge PR" on GitHub)
  ↓
GitHub webhook triggers Jenkins on main
  ↓
Jenkins re-runs all tests on merged code
  ↓
Tests pass ✓
  ↓
⏸️ CODE REVIEW APPROVAL GATE blocks pipeline
  ↓
(DevOps reviewer clicks "APPROVE & DEPLOY")
  ↓
Deploy to AWS/Local Docker
  ↓
Email notification: "Build #55 DEPLOYED"
```

**Scenario 3: PR Merge (REQUIRE_CODE_REVIEW=false)**

```
$ (PR gets 2+ approvals)
$ (Click "Merge PR" on GitHub)
  ↓
GitHub webhook triggers Jenkins on main
  ↓
Jenkins re-runs all tests on merged code
  ↓
Tests pass ✓
  ↓
Skip approval gate (disabled)
  ↓
Deploy to AWS/Local Docker
  ↓
Email notification: "Build #55 DEPLOYED"
```

**Scenario 4: Post-Merge Tests Fail**

```
$ (PR gets 2+ approvals)
$ (Click "Merge PR" on GitHub)
  ↓
GitHub webhook triggers Jenkins on main
  ↓
Jenkins re-runs all tests on merged code
  ↓
❌ Tests FAIL (merge conflict, incompatibility, etc.)
  ↓
Pipeline stops - NO DEPLOYMENT ✅
  ↓
Email notification: "Build #55 FAILED"
  ↓
Developers must fix on main and push correction
```

For detailed pipeline visualization, see [JENKINSFILE_WORKFLOW_DIAGRAM.md](JENKINSFILE_WORKFLOW_DIAGRAM.md).

### Jenkins Credentials Required

The pipeline requires these credentials to be configured in Jenkins:

| Credential ID         | Type        | Purpose                                     |
| --------------------- | ----------- | ------------------------------------------- |
| `team-email`          | Secret text | Email for build notifications (destination) |
| `mongo-root-username` | Secret text | MongoDB root username                       |
| `mongo-root-password` | Secret text | MongoDB root password                       |
| `api-gateway-url`     | Secret text | API Gateway URL for deployment              |
| `github-token`        | Secret text | GitHub Personal Access Token                |
| `sonarqube-token`     | Secret text | SonarQube authentication token              |
| `frontend-ssl-cert`   | Secret file | SSL certificate for HTTPS                   |
| `frontend-ssl-key`    | Secret file | SSL private key for HTTPS                   |

### Test Report Files

After build completion, test results are archived:

- **Backend Tests**: `**/target/surefire-reports/*.xml` - JUnit test results
- **Frontend Tests**: `buy-01-ui/coverage/` - Karma/Jasmine coverage reports
- **SonarQube Reports**: `target/sonar/report-task.txt` - Quality gate results
- **Build Artifacts**: Accessible in Jenkins UI under "Artifacts" section

---

## 🔍 SonarQube Code Quality & Security Analysis

### Overview

SonarQube is integrated into the CI/CD pipeline to enforce code quality standards and identify security vulnerabilities before deployment. The analysis runs automatically on every commit and **blocks deployment** if quality gates fail.

### ✅ Functional Requirements

#### 1. SonarQube Web Interface Access

**URL**: http://localhost:9000

**Credentials**:
- **Username**: `admin`
- **Password**: `admin123`

**Configured Projects**:
1. **SafeZone E-Commerce Platform** (`safezone-ecommerce`)
   - Language: Java 17 / XML
   - Lines of Code: ~2,900
   - Quality Profile: Sonar way
   
2. **SafeZone Frontend** (`safezone-frontend`)
   - Language: TypeScript / CSS / HTML
   - Lines of Code: ~6,000
   - Quality Profile: Sonar way

**Status**: ✅ Accessible and fully configured

#### 2. GitHub Integration

SonarQube is integrated through the Jenkins CI/CD pipeline:

**Integration Flow**:
```
GitHub Push → GitHub Webhook → Jenkins Build → SonarQube Analysis → Quality Gate Check → Deploy (if passed)
```

**Webhook Configuration**:
- **Jenkins Webhook**: GitHub repository configured to trigger Jenkins on push
- **SonarQube Webhook**: SonarQube sends Quality Gate results back to Jenkins
  - URL: `http://host.docker.internal:8088/sonarqube-webhook/`
  - Scope: Global (all projects)
  - Status: ✅ Active (Last delivery: < 1 second)

**Trigger Behavior**: Every push to any branch triggers code analysis automatically.

**Status**: ✅ Fully integrated with automatic triggers

#### 3. Docker-Based SonarQube Setup

SonarQube runs in Docker containers for consistent, reproducible environments.

**Container Configuration**:

```yaml
# From docker-compose.yml
sonarqube:
  container_name: buy01-sonarqube
  image: sonarqube:community
  ports:
    - "9000:9000"
  environment:
    - SONAR_JDBC_URL=jdbc:postgresql://sonarqube-db:5432/sonar
    - SONAR_JDBC_USERNAME=sonar
    - SONAR_JDBC_PASSWORD=sonar
  depends_on:
    - sonarqube-db
  volumes:
    - sonarqube_data:/opt/sonarqube/data
    - sonarqube_logs:/opt/sonarqube/logs
    - sonarqube_extensions:/opt/sonarqube/extensions

sonarqube-db:
  container_name: buy01-sonarqube-db
  image: postgres:15
  environment:
    - POSTGRES_USER=sonar
    - POSTGRES_PASSWORD=sonar
    - POSTGRES_DB=sonar
  volumes:
    - postgresql_data:/var/lib/postgresql/data
```

**Start SonarQube**:

```bash
docker-compose up -d sonarqube sonarqube-db
```

**Verify**:

```bash
docker ps | grep sonarqube
# Expected: buy01-sonarqube running on port 9000
```

**Status**: ✅ Configured and running in Docker

#### 4. Automated Code Analysis in CI/CD Pipeline

The Jenkins pipeline includes dedicated SonarQube analysis stages:

**Pipeline Stage Configuration** (from `Jenkinsfile`):

```groovy
stage('SonarQube Analysis') {
    parallel {
        stage('Backend Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh "mvn sonar:sonar -Dsonar.branch.name=${branch}"
                }
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Backend Quality Gate failed: ${qg.status}"
                        }
                    }
                }
            }
        }
        stage('Frontend Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh "npx sonarqube-scanner -Dsonar.branch.name=${branch}"
                }
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Frontend Quality Gate failed: ${qg.status}"
                        }
                    }
                }
            }
        }
    }
}
```

**Analysis Behavior**:
- **Parallel Execution**: Backend and frontend analyzed simultaneously (faster builds)
- **Inline Quality Gate Checks**: Each project validated immediately after analysis
- **Pipeline Blocking**: If either backend OR frontend fails Quality Gate, deployment is blocked
- **Fast Validation**: Webhook reduces Quality Gate wait time from 10 minutes to < 5 seconds

**Example - Pipeline Correctly Fails on Quality Issues** (Build #16):

```
[Pipeline] stage
[Pipeline] { (Backend Analysis)
...
SonarQube task 'efd12678-46be-4d92-87e3-eeed3e57abaf' completed. Quality gate is 'ERROR'
[Pipeline] error
ERROR: Backend Quality Gate failed: ERROR
[Pipeline] stage
[Pipeline] { (Deploy)
Stage "Deploy" skipped due to earlier failure(s)
Finished: FAILURE
```

**Status**: ✅ Automated analysis that correctly fails on quality issues

#### 5. Code Review and Approval Process

**Multi-Layer Quality Enforcement**:

1. **SonarQube Quality Gate** (Automated)
   - New Issues > 0 = FAIL
   - Security Hotspots reviewed = PASS
   - Coverage on New Code > 0% (if available)
   
2. **Jenkins Pipeline Validation** (Automated)
   - Backend Quality Gate must pass
   - Frontend Quality Gate must pass
   - All tests must pass
   
3. **GitHub Pull Request Review** (Manual)
   - Requires code review approval
   - All CI checks must pass (including SonarQube)
   - Merge only after approval

**Code Quality Improvement Workflow**:

```
1. Developer commits code
2. Jenkins triggers SonarQube analysis
3. Quality Gate fails (e.g., 2 new issues found)
4. Pipeline blocks deployment
5. Developer reviews issues in SonarQube UI
6. Developer fixes issues in code
7. Developer commits fixes
8. Jenkins re-analyzes (Quality Gate passes)
9. Code merged and deployed
```

**Real Example - Build #16 → Build #18**:

- **Build #16**: Backend Quality Gate FAILED (2 issues)
  - Issue 1: `S2699` - Test without assertion
  - Issue 2: `S5786` - Public modifier in JUnit5 test class
  
- **Build #17**: Fixed issue #1 (commit `52f2a9c`)
  - Replaced `assert` with `assertNotNull()`
  
- **Build #18**: Fixed issue #2 (commit `4fbc850`)
  - Changed `public class` to `class` (package-private)
  - Pipeline PASSED ✅

**Status**: ✅ Code review process in place with automated quality gates

---

### 🧠 Comprehension - How It Works

#### SonarQube Setup Steps

**1. Installation via Docker Compose**

```bash
# Start SonarQube and PostgreSQL database
docker-compose up -d sonarqube sonarqube-db

# Wait for initialization (first start takes ~2 minutes)
docker logs -f buy01-sonarqube

# Access UI at http://localhost:9000
# Default credentials: admin / admin
```

**2. Initial Configuration**

```bash
# 1. Change default password (required on first login)
# 2. Create authentication token:
#    - Administration → Security → Users → admin → Tokens
#    - Generate token (copy immediately)
```

**3. Jenkins Integration**

In Jenkins:
```
Manage Jenkins → System → SonarQube Servers
- Name: SonarQube
- Server URL: http://host.docker.internal:9000
- Server authentication token: <token from step 2>
```

**4. Project Configuration**

Projects auto-created during first analysis. Configuration in:
- **Backend**: `pom.xml` (Maven Sonar plugin)
- **Frontend**: `buy-01-ui/sonar-project.properties`

```properties
# Frontend configuration
sonar.projectKey=safezone-frontend
sonar.projectName=SafeZone Frontend
sonar.sources=src
sonar.tests=src
sonar.test.inclusions=**/*.spec.ts
sonar.exclusions=**/node_modules/**,**/dist/**,**/coverage/**
```

**5. Webhook Configuration**

In SonarQube:
```
Administration → Configuration → Webhooks → Create
- Name: Jenkins
- URL: http://host.docker.internal:8088/sonarqube-webhook/
- Scope: Global (applies to all projects)
```

---

#### CI/CD Integration Flow

**Complete Analysis Flow with Timing**:

```
┌─────────────────────────────────────────────────────────────────────┐
│ 1. Developer Pushes Code to GitHub                                 │
│    git push origin main                                             │
└──────────────────────┬──────────────────────────────────────────────┘
                       │ (< 1 second)
                       ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 2. GitHub Webhook Triggers Jenkins                                 │
│    POST https://jenkins.example.com/github-webhook/                │
└──────────────────────┬──────────────────────────────────────────────┘
                       │ (< 1 second)
                       ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 3. Jenkins Clones Repository (Checkout Stage)                      │
│    git clone https://github.com/user/SafeZone.git                  │
│    Location: /var/jenkins_home/workspace/pipeline_main/            │
└──────────────────────┬──────────────────────────────────────────────┘
                       │ (~3 seconds)
                       ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 4. Build Stage                                                      │
│    mvn clean install -DskipTests                                    │
└──────────────────────┬──────────────────────────────────────────────┘
                       │ (~6 seconds)
                       ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 5. Test Stage (Parallel)                                            │
│    ├─ Backend: mvn test          (15 tests in 16s)                 │
│    └─ Frontend: npm test          (2 tests in 3s)                  │
└──────────────────────┬──────────────────────────────────────────────┘
                       │ (~16 seconds - parallel)
                       ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 6. SonarQube Analysis Stage (Parallel)                             │
│                                                                     │
│  ┌─────────────────────┐         ┌─────────────────────┐          │
│  │ Backend Analysis    │         │ Frontend Analysis   │          │
│  │                     │         │                     │          │
│  │ 1. mvn sonar:sonar  │         │ 1. npx sonarqube-   │          │
│  │    Reads: Java/XML  │         │    scanner          │          │
│  │    Location: /var/  │         │    Reads: TS/CSS    │          │
│  │    jenkins_home/... │         │    Location: /var/  │          │
│  │                     │         │    jenkins_home/... │          │
│  │ 2. Sends data to    │         │    /buy-01-ui/      │          │
│  │    SonarQube server │         │                     │          │
│  │    (localhost:9000) │         │ 2. Sends data to    │          │
│  │                     │         │    SonarQube server │          │
│  │ 3. Analysis task    │         │                     │          │
│  │    Task ID: efd1... │         │ 3. Analysis task    │          │
│  │                     │         │    Task ID: fa39... │          │
│  └──────────┬──────────┘         └──────────┬──────────┘          │
│             │ (~10 seconds)                 │ (~11 seconds)       │
└─────────────┼───────────────────────────────┼─────────────────────┘
              │                               │
              ↓                               ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 7. SonarQube Server Processing                                     │
│    ├─ Parse code structure                                         │
│    ├─ Apply analysis rules (Sonar way profile)                     │
│    ├─ Detect issues (bugs, vulnerabilities, code smells)           │
│    ├─ Calculate metrics (coverage, duplication, complexity)        │
│    └─ Evaluate Quality Gate conditions                             │
└──────────────────────┬──────────────────────────────────────────────┘
                       │ (~2-3 seconds per project)
                       ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 8. SonarQube Sends Webhook to Jenkins                              │
│    POST http://host.docker.internal:8088/sonarqube-webhook/        │
│    Payload: {                                                       │
│      "serverUrl": "http://localhost:9000",                          │
│      "taskId": "efd12678...",                                       │
│      "status": "SUCCESS",                                           │
│      "qualityGate": {                                               │
│        "status": "OK",  // or "ERROR"                               │
│        "conditions": [...]                                          │
│      }                                                              │
│    }                                                                │
└──────────────────────┬──────────────────────────────────────────────┘
                       │ (~64 milliseconds - webhook delivery)
                       ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 9. Jenkins Quality Gate Check (waitForQualityGate)                 │
│                                                                     │
│  ┌─────────────────────┐         ┌─────────────────────┐          │
│  │ Backend QG Check    │         │ Frontend QG Check   │          │
│  │                     │         │                     │          │
│  │ if (qg.status       │         │ if (qg.status       │          │
│  │     != 'OK') {      │         │     != 'OK') {      │          │
│  │   error "Backend    │         │   error "Frontend   │          │
│  │   Quality Gate      │         │   Quality Gate      │          │
│  │   failed: ERROR"    │         │   failed: ERROR"    │          │
│  │ }                   │         │ }                   │          │
│  └─────────────────────┘         └─────────────────────┘          │
│                                                                     │
│  Both must pass to continue pipeline                               │
└──────────────────────┬──────────────────────────────────────────────┘
                       │ (< 5 seconds with webhook)
                       ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 10. Deploy Stage (Only if Quality Gates PASSED)                    │
│     docker-compose up -d --build                                    │
└─────────────────────────────────────────────────────────────────────┘

Total Time: ~45 seconds (with webhook optimization)
Without webhook: ~10-15 minutes (polling every 5 seconds)
```

**Key Points**:

1. **Source of Code**: Jenkins analyzes LOCAL copy (not GitHub directly)
   - Jenkins clones code to: `/var/jenkins_home/workspace/pipeline_main/`
   - SonarQube scanners read files from this location
   - Analysis results sent to SonarQube server for storage

2. **Webhook Performance**:
   - **Without webhook**: Jenkins polls SonarQube API every 5s → 5-10 min wait
   - **With webhook**: SonarQube pushes result immediately → < 5 sec wait
   - **Webhook log**: `Webhooks | globalWebhooks=1 | status=SUCCESS | time=64ms`

3. **Parallel Analysis**:
   - Backend and frontend analyzed simultaneously
   - Each has independent Quality Gate check
   - Pipeline fails if EITHER project fails Quality Gate

---

#### SonarQube Functionality & Code Quality Contribution

**Role in Project**:

SonarQube acts as an **automated code reviewer** that:

1. **Identifies Code Smells**
   - Duplicated code blocks
   - Complex methods (cyclomatic complexity > 10)
   - Unused variables/imports
   - Poor naming conventions

2. **Detects Bugs**
   - Null pointer exceptions
   - Resource leaks
   - Incorrect API usage
   - Logic errors

3. **Finds Security Vulnerabilities**
   - SQL injection risks
   - Cross-site scripting (XSS)
   - Weak encryption
   - Authentication issues

4. **Enforces Test Quality**
   - Tests without assertions
   - Low test coverage
   - Skipped tests

**Code Quality Improvement Process**:

```
Developer writes code with issues
         ↓
SonarQube analysis identifies 2 new issues
         ↓
Quality Gate fails (New Issues > 0)
         ↓
Pipeline blocks deployment
         ↓
Developer views issues in SonarQube UI:
  - Issue 1: Test without assertion (S2699)
    Location: ServiceRegistryApplicationTest.java:11
    Severity: Major
    Fix: Replace assert with assertNotNull()
  
  - Issue 2: Public test class (S5786)
    Location: AuthenticationServiceTest.java:29
    Severity: Info
    Fix: Remove public modifier
         ↓
Developer fixes both issues
         ↓
Commits fixes to GitHub
         ↓
Jenkins re-analyzes code
         ↓
Quality Gate passes (0 new issues)
         ↓
Deployment proceeds
```

**Measurable Impact**:

- **Before SonarQube**: No automated code quality checks
- **After SonarQube**: 
  - 2 code quality issues identified and fixed in Build #16-18
  - 100% of new issues resolved before deployment
  - Zero security vulnerabilities deployed to production
  - Consistent code quality standards enforced

---

### 🔒 Security - Permissions and Access Controls

#### Current Security Configuration

**⚠️ IMPORTANT**: Projects are currently configured as **Public** by default. Follow these steps to secure your SonarQube instance:

#### Recommended Security Configuration

**1. Change Default Project Visibility**

```
Administration → Projects → Management
- Default visibility of new projects: Private ✅
```

**2. Update Existing Projects to Private**

For each project:
```
Project → Administration → Permissions → Change to "Private"
```

Or via API:
```bash
curl -u admin:admin123 -X POST \
  "http://localhost:9000/api/projects/update_visibility?project=safezone-ecommerce&visibility=private"

curl -u admin:admin123 -X POST \
  "http://localhost:9000/api/projects/update_visibility?project=safezone-frontend&visibility=private"
```

**3. User and Group Permissions**

**Administration → Security → Groups**:

| Group                | Permissions             | Description                |
| -------------------- | ----------------------- | -------------------------- |
| sonar-administrators | All (Administer System) | Full admin access          |
| sonar-users          | Browse projects         | Authenticated users        |
| Anyone               | None ❌                  | Unauthenticated users      |

**4. Create Jenkins Service Account (Best Practice)**

Instead of using admin token:

```
Administration → Security → Users → Create User
- Login: jenkins
- Name: Jenkins CI
- Password: <strong-password>
- Groups: sonar-users

Users → jenkins → Tokens → Generate Token
- Name: jenkins-ci
- Copy token and update Jenkins credential
```

**5. Permission Matrix**

| Permission           | Admin | Jenkins CI | Developers | Public |
| -------------------- | ----- | ---------- | ---------- | ------ |
| Browse Projects      | ✅     | ✅          | ✅          | ❌      |
| Execute Analysis     | ✅     | ✅          | ❌          | ❌      |
| Administer Projects  | ✅     | ❌          | ❌          | ❌      |
| Administer System    | ✅     | ❌          | ❌          | ❌      |
| Create Projects      | ✅     | ❌          | ❌          | ❌      |
| Administer Quality   | ✅     | ❌          | ❌          | ❌      |

**Status**: ⚠️ Requires configuration - Follow steps above to secure

---

### ✅ Code Quality and Standards

#### SonarQube Rules Configuration

**Quality Profiles Used**:

| Language   | Profile    | Rules Count | Description                |
| ---------- | ---------- | ----------- | -------------------------- |
| Java       | Sonar way  | 500+        | Default Java rules         |
| TypeScript | Sonar way  | 300+        | Default TypeScript rules   |
| XML        | Sonar way  | 50+         | Maven POM validation       |
| CSS        | Sonar way  | 100+        | CSS best practices         |
| HTML       | Sonar way  | 50+         | HTML accessibility & clean |

**Quality Gate Conditions**:

```
Condition                          | Threshold | Status
-----------------------------------|-----------|--------
New Issues                         | > 0       | ❌ FAIL
Security Hotspots Reviewed         | < 100%    | ❌ FAIL
Coverage on New Code               | < 0%      | ⚠️  WARN
```

**Rules Configured Correctly**: ✅ YES

- All rules active in "Sonar way" profile
- No custom rule modifications (using industry standards)
- Quality gates enforce zero new issues policy

#### Code Quality Issues Identified & Fixed

**Real Example from Build #16-18**:

**Issue 1: Missing Test Assertion (S2699)**

- **File**: `service-registry/src/test/java/.../ServiceRegistryApplicationTest.java`
- **Line**: 11
- **Severity**: Major
- **Issue**: Test method without any assertion
- **Original Code**:
  ```java
  @Test
  void testApplicationExists() {
      assert ServiceRegistryApplication.class != null;
  }
  ```
- **Problem**: Java `assert` keyword is not a proper test assertion
- **Fixed Code** (Commit `52f2a9c`):
  ```java
  import static org.junit.jupiter.api.Assertions.assertNotNull;
  
  @Test
  void testApplicationExists() {
      assertNotNull(ServiceRegistryApplication.class);
  }
  ```
- **Result**: ✅ Issue resolved

**Issue 2: Public JUnit5 Test Class (S5786)**

- **File**: `user-service/src/test/java/.../AuthenticationServiceTest.java`
- **Line**: 29
- **Severity**: Info
- **Issue**: JUnit 5 test classes should have default package visibility
- **Original Code**:
  ```java
  @ExtendWith(MockitoExtension.class)
  @DisplayName("AuthenticationService Unit Tests")
  public class AuthenticationServiceTest {
  ```
- **Problem**: JUnit 5 doesn't require `public` modifier (best practice)
- **Fixed Code** (Commit `4fbc850`):
  ```java
  @ExtendWith(MockitoExtension.class)
  @DisplayName("AuthenticationService Unit Tests")
  class AuthenticationServiceTest {
  ```
- **Result**: ✅ Issue resolved

**Issues Addressed and Committed**: ✅ YES

- Both issues fixed within 10 minutes of identification
- Fixes committed to GitHub main branch
- Build #18 passed Quality Gate with 0 new issues
- Code quality improved and verified

---

### 🎁 Bonus Features (Optional)

#### Email/Slack Notifications

**Status**: ❌ Not Implemented

**How to Enable**:

1. **Email Notifications**:
   ```
   Administration → Configuration → General Settings → Email
   - SMTP host: smtp.gmail.com
   - SMTP port: 587
   - From: sonarqube@example.com
   ```

2. **Slack Notifications** (requires plugin):
   ```
   Administration → Marketplace → Search "Slack"
   Install → Restart → Configure webhook URL
   ```

#### IDE Integration

**Status**: ❌ Not Implemented

**Supported IDEs**:

- **Visual Studio Code**: SonarLint extension
- **IntelliJ IDEA**: SonarLint plugin
- **Eclipse**: SonarLint plugin

**Benefits**:
- Real-time code quality feedback as you type
- Issues highlighted directly in editor
- Fix suggestions with one-click remediation

**Installation Example (VS Code)**:
```
Extensions → Search "SonarLint" → Install
Settings → SonarQube Connections → Add server URL
```

---

## 🏗️ Architecture Overview

This project implements a modern microservices architecture with the following components:

### Backend Services (Spring Boot 3.5.6 + Java 17)

- **API Gateway** (Port 8080) - HTTP entry point with routing and CORS configuration
- **Service Registry** (Port 8761) - Eureka service discovery for dynamic service registration
- **User Service** (Port 8081) - User authentication, JWT management, and profile handling
- **Product Service** (Port 8082) - Product catalog, inventory, and seller management
- **Media Service** (Port 8083) - File uploads, media storage, and image management

### Frontend

- **Angular 20** (Ports 4201) - Modern SPA with Angular Material Design

  - HTTPS on port 4201 (with self-signed certificates)

### Infrastructure

- **Apache Kafka** - Event-driven messaging for cascade operations and data consistency
- **Zookeeper** - Kafka coordination and cluster management
- **MongoDB 6.0** - NoSQL database with database-per-service pattern

## ✨ Key Features

### Authentication & Authorization

- 🔐 **JWT Authentication** with secure token-based auth
- 👥 **Role-Based Access Control** (SELLER, CLIENT, ADMIN)
- 🔑 **Password Management** with secure hashing
- 👤 **User Profiles** with avatar upload and management

### Architecture & Scalability

- 📨 **Event-Driven Architecture** using Kafka for cascade operations
- 🎯 **Service Discovery** with Eureka for dynamic load balancing
- 🗄️ **Database per Service** pattern for data isolation
- 🐳 **Fully Dockerized** - one command deployment
- 🔄 **CORS Configuration** for cross-origin requests
- ♻️ **Clean Code** - refactored with DRY principles and helper methods for maintainability

### Product & Media Management

- 📦 **Product CRUD** with seller dashboard
- 📁 **Multi-File Upload** with validation (images, documents)
- 🖼️ **Image Management** with preview and lightbox
- 📊 **Media Analytics** and tracking

### User Experience

- 🎨 **Modern Material UI** with responsive design
- ⚡ **Reactive Forms** with real-time validation
- 🔔 **Notification System** for user feedback
- 🛡️ **Client-Side Guards** for route protection
- 🌓 **Dark/Light Theme** support (Material theming)

## 🚀 Quick Start

### Prerequisites

- **Docker** - Required for containerized deployment
- **Java 17+** - For local development (optional)
- **Node.js 18+** and npm - For frontend development (optional)
- **Maven 3.6+** - For building services locally (optional)

### One-Command Deployment (Recommended)

The easiest way to run the entire application:

```bash
# Clone the repository
git clone https://github.com/jeeeeedi/buy-01.git
cd buy-01

# Or use the provided helper script
./start_docker.sh

# Check services status
docker-compose ps
```

**Helper Scripts Available:**

- `./start_all.sh` - Builds and starts all services (Docker + local builds)
- `./stop_all.sh` - Stops all running services
- `./start_docker.sh` - Starts only Docker infrastructure (Kafka, MongoDB, Zookeeper)
- `./shutdown_all.sh` - Gracefully shuts down all containers

**Access the application:**

- 🔒 **Frontend (HTTPS)**: https://localhost:4201 (self-signed certificate)
- 🔌 **API Gateway**: http://localhost:8080
- 📊 **Eureka Dashboard**: http://localhost:8761
- 🗄️ **MongoDB**: mongodb://root:example@localhost:27017

### Local Development Setup

For development with hot-reload:

1. **Start infrastructure only:**

```bash
docker-compose up -d zookeeper kafka mongodb
```

2. **Run backend services:**

```bash
# Build all services
mvn clean install

# Start services (each in separate terminal)
cd service-registry && mvn spring-boot:run
cd api-gateway && mvn spring-boot:run
cd user-service && mvn spring-boot:run
cd product-service && mvn spring-boot:run
cd media-service && mvn spring-boot:run
```

3. **Run frontend with hot-reload:**

```bash
cd buy-01-ui
npm install
npm start
```

### First Time Setup

After starting the application, you can:

1. **Register a new account:**

   - Navigate to http://localhost:4200
   - Click "Register" and create an account
   - Choose role: SELLER (to sell products) or CLIENT (to buy products)

2. **Verify services:**

   - Check Eureka dashboard: http://localhost:8761
   - All services should show as "UP"

3. **Start using the platform:**
   - **Sellers**: Upload products, manage inventory, upload media
   - **Clients**: Browse products, view details, manage profile

## 📊 Service Ports & URLs

| Service          | Port  | Protocol | URL                       | Description           |
| ---------------- | ----- | -------- | ------------------------- | --------------------- |
| Frontend (HTTPS) | 4201  | HTTPS    | https://localhost:4201    | Secure frontend       |
| API Gateway      | 8080  | HTTP     | http://localhost:8080     | Main API entry point  |
| Service Registry | 8761  | HTTP     | http://localhost:8761     | Eureka dashboard      |
| User Service     | 8081  | HTTP     | Internal                  | User management       |
| Product Service  | 8082  | HTTP     | Internal                  | Product management    |
| Media Service    | 8083  | HTTP     | Internal                  | Media/file management |
| MongoDB          | 27017 | TCP      | mongodb://localhost:27017 | Database server       |
| Kafka            | 9092  | TCP      | localhost:9092            | Message broker        |
| Zookeeper        | 2182  | TCP      | localhost:2182            | Kafka coordination    |

**Note:** Internal services (User, Product, Media) communicate through the API Gateway and are not directly exposed.

## 🔄 Event-Driven Flow

The system uses Kafka for cascade deletion operations and data consistency:

```
User Deletion → Kafka Topic: user.deleted → Product Service & Media Service
                                          ↓                    ↓
                              Delete User's Products    Delete User's Media
                                          ↓
                              Kafka Topic: product.deleted
                                          ↓
                                     Media Service
                                          ↓
                              Delete Product Media Files
```

**Key Points:**

- When a user is deleted, both product and media services receive the event
- Product service deletes all products owned by that user and publishes `product.deleted` events
- Media service receives `product.deleted` events and cleans up associated media files
- Media service also directly handles user deletions to remove orphaned media
- All file deletions are handled by a centralized helper method to avoid code duplication

## Kafka & MongoDB

### Kafka Overview

- **Producers:** `user-service` publishes `user.deleted` (minimal payload, typically the user id). `product-service` deletes products and publishes `product.deleted` events (preferred payload is JSON with `id` and `mediaIds`).
- **Consumers:** `product-service` listens for `user.deleted` and deletes the user's products. `media-service` listens for `product.deleted` and deletes media. `media-service` also listens for `user.deleted` as a fallback to remove user-owned media.
- **Topics:** `user.deleted`, `product.deleted` (created by each service via `KafkaTopicConfig` beans).
- **Message formats:** prefer small, typed JSON events like `{ "id": "<productId>", "mediaIds": ["<mediaId>", ...] }`. Consumers also accept older plain-string messages containing the product id.

**Kafka - Docker commands (list topics, consume, produce)**

- **List all topics:**

```bash
docker exec -it buy-01-kafka-1 /bin/bash -c \
  "/usr/bin/kafka-topics --bootstrap-server localhost:9092 --list"
```

- **Consume messages from a topic (show headers):**

```bash
docker exec -it buy-01-kafka-1 /bin/bash -c \
  "/usr/bin/kafka-console-consumer --bootstrap-server localhost:9092 --topic product.deleted --from-beginning --property print.headers=true"
```

- **Produce a JSON message to a topic (useful for tests):**

```bash
echo '{"id":"69246f37ee23ecd66ed8ca65","mediaIds":["69246f370ca32276270f8123"]}' \
  | docker exec -i buy-01-kafka-1 /usr/bin/kafka-console-producer --bootstrap-server localhost:9092 --topic product.deleted
```

- **Produce a plain product id (legacy):**

```bash
echo "69246f37ee23ecd66ed8ca65" | docker exec -i buy-01-kafka-1 /usr/bin/kafka-console-producer --bootstrap-server localhost:9092 --topic product.deleted
```

### MongoDB

- **Connect using `mongosh` from your host (local port mapping):**

```bash
mongosh "mongodb://root:example@localhost:27017/?authSource=admin"
```

- **Or exec into the MongoDB container and launch `mongosh`:**

```bash
docker exec -it buy-01-mongodb-1 mongosh -u root -p example --authenticationDatabase admin
```

- **Inspect media DB and collection (example):**

```bash
// list databases
show dbs

// switch to the product DB
use productdb

// list collections
show collections

// show a few documents
db.products.find().limit(5).pretty()

// find media by userId
db.media.find({ userId: "69244af654df39660cbd3294" }).pretty()

// delete media by ObjectId (if _id is an ObjectId)
db.media.deleteOne({ _id: ObjectId("69246f370ca32276270f8123") })

// Count all documents in the collection
db.media.countDocuments({})

// Count documents matching a filter (e.g. media owned by a user)
db.media.countDocuments({ userId: "69244af654df39660cbd3294" })
```

## 🗂️ Project Structure

```
buy-01/
├── api-gateway/              # API Gateway with routing and CORS
│   ├── src/main/
│   │   ├── java/.../apigateway/
│   │   │   ├── ApiGatewayApplication.java
│   │   │   └── config/
│   │   │       └── CorsConfig.java       # CORS configuration
│   │   └── resources/
│   │       ├── application.properties
│   │       ├── application-docker.yml
│   │       └── application.yml           # Route definitions
│   ├── Dockerfile
│   └── pom.xml
│
├── service-registry/         # Eureka server for service discovery
│   ├── src/main/
│   │   ├── java/.../serviceregistry/
│   │   │   └── ServiceRegistryApplication.java
│   │   └── resources/
│   │       └── application.properties
│   ├── Dockerfile
│   └── pom.xml
│
├── user-service/             # User management & authentication
│   ├── src/main/
│   │   ├── java/.../user/
│   │   │   ├── UserServiceApplication.java
│   │   │   ├── config/          # JWT, Security, Kafka
│   │   │   ├── controller/      # REST controllers
│   │   │   ├── model/           # User, Role entities
│   │   │   ├── repository/      # MongoDB repositories
│   │   │   └── service/         # Business logic
│   │   └── resources/
│   │       └── application.properties
│   ├── Dockerfile
│   └── pom.xml
│
├── product-service/          # Product catalog management
│   ├── src/main/
│   │   ├── java/.../product/
│   │   │   ├── ProductServiceApplication.java
│   │   │   ├── config/          # Security, Kafka, MongoDB
│   │   │   ├── controller/      # Product REST API
│   │   │   ├── dto/             # Request/Response DTOs
│   │   │   ├── model/           # Product entity
│   │   │   ├── repository/      # Product repository
│   │   │   └── service/         # Product logic, Kafka consumer
│   │   └── resources/
│   │       └── application.properties
│   ├── Dockerfile
│   └── pom.xml
│
├── media-service/            # Media file management
│   ├── src/main/
│   │   ├── java/.../media/
│   │   │   ├── MediaServiceApplication.java
│   │   │   ├── config/          # Storage, Security, Kafka
│   │   │   ├── controller/      # Media upload/download
│   │   │   ├── model/           # Media entity
│   │   │   ├── repository/      # Media repository
│   │   │   └── service/         # File handling, Kafka consumers
│   │   └── resources/
│   │       └── application.properties
│   ├── uploads/             # Local file storage
│   ├── Dockerfile
│   └── pom.xml
│
├── buy-01-ui/               # Angular 20 frontend
│   ├── src/
│   │   ├── app/
│   │   │   ├── core/            # Core services & infrastructure
│   │   │   │   ├── guards/      # Auth & role guards
│   │   │   │   ├── interceptors/ # HTTP interceptors
│   │   │   │   ├── services/    # Auth, Product, Media services
│   │   │   │   └── validators/  # Custom validators
│   │   │   ├── features/        # Feature modules
│   │   │   │   ├── auth/        # Login, Register
│   │   │   │   ├── products/    # Product list, detail
│   │   │   │   ├── profile/     # User profile
│   │   │   │   └── seller/      # Seller dashboard
│   │   │   └── shared/          # Shared components
│   │   │       ├── components/  # Reusable UI components
│   │   │       └── services/    # Shared services
│   │   ├── environments/        # Environment configs
│   │   │   ├── environment.ts
│   │   │   └── environment.prod.ts
│   │   ├── index.html
│   │   ├── main.ts
│   │   └── styles.css
│   ├── certs/                   # SSL certificates for HTTPS
│   │   ├── localhost.pem
│   │   └── localhost-key.pem
│   ├── nginx-https.conf         # Nginx config for HTTPS
│   ├── Dockerfile
│   ├── angular.json
│   ├── package.json
│   └── tsconfig.json
│
├── docker-compose.yml           # Multi-container orchestration
├── pom.xml                      # Maven parent POM
└── README.md                    # This file
```

## 🛠️ Technologies Used

### Backend

- Spring Boot 3.5.6
- Spring Cloud (Eureka, Gateway)
- Spring Security with JWT
- Spring Data MongoDB
- Spring Kafka
- Maven
- Lombok (for cleaner code with annotations)

### Frontend

- Angular 20
- Angular Material
- RxJS
- TypeScript 5.9

### Infrastructure

- Apache Kafka
- MongoDB 6.0
- Docker & Docker Compose
- Nginx (for HTTPS frontend)

### Code Quality

- DRY Principles (Don't Repeat Yourself)
- Helper methods for common operations
- Consistent error handling
- Clean architecture patterns

## 🔐 Security Features

- **JWT Tokens**: Stateless authentication with secure token generation and validation
- **Role-Based Authorization**: Fine-grained access control (SELLER, CLIENT, ADMIN)
- **Password Encryption**: Bcrypt hashing for secure password storage
- **CORS Configuration**: Properly configured to allow frontend-backend communication
- **Frontend HTTPS**: Optional HTTPS support with self-signed certificates (port 4201)
- **Input Validation**: Server-side and client-side validation for all inputs
- **File Upload Security**: File type and size validation, secure storage
- **JWT Secret**: Configurable secret key for token signing

## 🧪 Testing

**Backend Tests:**

```bash
mvn test
```

**Frontend Tests:**

```bash
cd buy-01-ui
npm test
```

## 📝 Environment Variables

Key environment variables (configured in `docker-compose.yml`):

```yaml
SPRING_KAFKA_BOOTSTRAP_SERVERS: kafka:9092
SPRING_DATA_MONGODB_URI: mongodb://root:example@mongodb:27017/{dbname}?authSource=admin
EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE: http://service-registry:8761/eureka/
```

## 🐛 Troubleshooting

### Services Not Starting

**Check all containers:**

```bash
docker-compose ps
docker-compose logs
```

**Restart specific service:**

```bash
docker-compose restart <service-name>
# Example: docker-compose restart api-gateway
```

**Rebuild after code changes:**

```bash
docker-compose build --no-cache <service-name>
docker-compose up -d <service-name>
```

### Kafka Issues

**Services can't connect to Kafka:**

```bash
# Check Kafka is running
docker ps | grep kafka

# View Kafka logs
docker-compose logs kafka

# List Kafka topics
docker exec -it buy-01-kafka-1 /bin/bash -c \
  "/usr/bin/kafka-topics --bootstrap-server localhost:9092 --list"
```

### Database Issues

**MongoDB connection failed:**

```bash
# Check MongoDB is running
docker ps | grep mongodb

# Test connection
docker exec -it buy-01-mongodb-1 mongosh -u root -p example

# View MongoDB logs
docker-compose logs mongodb
```

**Clear MongoDB data:**

```bash
# Stop services
docker-compose down

# Remove data volume (WARNING: This deletes all data!)
rm -rf ./uploads

# Restart
docker-compose up -d
```

### Frontend Issues

**Frontend can't reach backend:**

- Ensure API Gateway is running: http://localhost:8080
- Check browser console for CORS errors
- Verify environment configuration in `buy-01-ui/src/environments/`

**Mixed Content warnings (HTTPS frontend calling HTTP backend):**

- This is normal when using HTTPS frontend (port 4201)
- Use HTTP frontend (port 4200) for development
- Browser auto-upgrades requests, which is safe

### Service Discovery Issues

**Services not registering with Eureka:**

- Wait 30-60 seconds after startup for registration
- Check Eureka dashboard: http://localhost:8761
- Verify service logs: `docker-compose logs <service-name>`

### Port Conflicts

**Port already in use:**

```bash
# Find process using port (Windows)
netstat -ano | findstr :8080

# Find process using port (Mac/Linux)
lsof -i :8080

# Kill process or change port in docker-compose.yml
```

## 👥 User Management

### Registering Users

**Via Frontend (Recommended):**

1. Navigate to http://localhost:4200
2. Click "Register"
3. Fill in the form (name, email, password, role)
4. Choose role: SELLER or CLIENT

**Via API:**

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Seller",
    "email": "seller@example.com",
    "password": "password123",
    "role": "SELLER"
  }'
```

### User Roles

- **SELLER**: Can create, edit, and delete products; upload media; manage inventory
- **CLIENT**: Can browse products, view details, manage profile
- **ADMIN**: Full system access (future implementation)

## 📚 API Documentation

All API endpoints are accessed through the API Gateway: `http://localhost:8080`

### Authentication Endpoints

| Method | Endpoint                    | Description             | Auth Required |
| ------ | --------------------------- | ----------------------- | ------------- |
| POST   | `/api/auth/register`        | Register new user       | No            |
| POST   | `/api/auth/login`           | Login and get JWT token | No            |
| POST   | `/api/auth/change-password` | Change user password    | Yes           |

### User Endpoints

| Method | Endpoint                    | Description              | Auth Required | Role      |
| ------ | --------------------------- | ------------------------ | ------------- | --------- |
| GET    | `/api/users/profile`        | Get current user profile | Yes           | Any       |
| PUT    | `/api/users/profile`        | Update user profile      | Yes           | Any       |
| PUT    | `/api/users/profile/name`   | Update user name         | Yes           | Any       |
| POST   | `/api/users/profile/avatar` | Upload user avatar       | Yes           | Any       |
| DELETE | `/api/users/{id}`           | Delete user (cascade)    | Yes           | Own/Admin |

### Product Endpoints

| Method | Endpoint                        | Description              | Auth Required | Role           |
| ------ | ------------------------------- | ------------------------ | ------------- | -------------- |
| GET    | `/api/products`                 | Get all products         | No            | Any            |
| GET    | `/api/products/{id}`            | Get product by ID        | No            | Any            |
| GET    | `/api/products/seller/{userId}` | Get products by seller   | No            | Any            |
| POST   | `/api/products`                 | Create new product       | Yes           | SELLER         |
| PUT    | `/api/products/{id}`            | Update product           | Yes           | SELLER (owner) |
| DELETE | `/api/products/{id}`            | Delete product (cascade) | Yes           | SELLER (owner) |

### Media Endpoints

| Method | Endpoint                                     | Description                  | Auth Required | Role           |
| ------ | -------------------------------------------- | ---------------------------- | ------------- | -------------- |
| POST   | `/api/media/upload`                          | Upload media file            | Yes           | SELLER         |
| POST   | `/api/media/upload-multiple`                 | Upload multiple files        | Yes           | SELLER         |
| GET    | `/api/media/{id}`                            | Get media by ID              | No            | Any            |
| GET    | `/api/media/user/{userId}`                   | Get user's media             | Yes           | Own/SELLER     |
| GET    | `/api/media/download/{filename}`             | Download file                | No            | Any            |
| DELETE | `/api/media/{id}`                            | Delete media                 | Yes           | SELLER (owner) |
| POST   | `/api/media/{mediaId}/associate/{productId}` | Associate media with product | Yes           | SELLER         |

### Request Examples

**Login:**

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "seller@example.com",
    "password": "password123"
  }'
```

**Create Product (requires JWT token):**

```bash
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "name": "Product Name",
    "description": "Product description",
    "price": 99.99,
    "category": "Electronics",
    "stock": 10
  }'
```

**Upload Media:**

```bash
curl -X POST http://localhost:8080/api/media/upload \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "file=@/path/to/image.jpg"
```

## 🎯 Use Cases

### For Sellers

1. **Register as SELLER** → Access seller dashboard
2. **Upload Media** → Add product images
3. **Create Products** → List items with details, pricing, and images
4. **Manage Inventory** → Edit or delete products
5. **View Analytics** → Track product performance

### For Clients

1. **Register as CLIENT** → Browse marketplace
2. **View Products** → Search and filter products
3. **Product Details** → View images, descriptions, pricing
4. **Manage Profile** → Update info and avatar

### System Features

- **Cascade Deletion**: Deleting a user automatically removes their products and associated media
- **Event-Driven**: Kafka ensures data consistency across services
- **Service Discovery**: Eureka enables dynamic service registration and load balancing

## 🚧 Future Enhancements

- 🛒 Shopping cart functionality
- 💳 Payment integration
- 📧 Email notifications
- 🔍 Advanced search and filtering
- ⭐ Product reviews and ratings
- 📊 Seller analytics dashboard
- 🌐 Multi-language support
- 📱 Mobile app (React Native)

## 📖 Documentation

### For Developers

- **Backend**: Spring Boot REST APIs with Spring Security
- **Frontend**: Angular with reactive patterns and Material UI
- **Database**: MongoDB with database-per-service pattern
- **Messaging**: Kafka for event-driven architecture
- **Containerization**: Docker Compose for multi-container deployment

### Key Design Patterns

- Microservices Architecture
- API Gateway Pattern
- Service Discovery Pattern
- Event-Driven Architecture
- Database per Service
- JWT Authentication

## 👨‍💻 Contributors

- [@jeeeeedi](https://github.com/jeeeeedi)
- [@oafilali](https://github.com/oafilali)
# Testing deployment from main branch
# Test Multibranch Pipeline deployment
# Docker socket permissions fixed
