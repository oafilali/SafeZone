# Jenkinsfile Manual Update Guide

Due to the complexity of the automated replacements, here's a **simple manual approach** to update the Jenkinsfile:

## 🎯 Critical Changes Needed

### Change 1: SonarQube Analysis Stage (~Line 200-250)

**Find this section:**
```groovy
// Load SonarQube token based on whether we're using override or Jenkins credentials
if (params.SONAR_TOKEN_OVERRIDE?.trim()) {
    ...entire if-else block...
}
```

**Replace with:**
```groovy
// Use Jenkins credential for SonarQube token
echo "🔑 Using SonarQube Token from Jenkins Credentials"
withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
    withSonarQubeEnv('SonarQube') {
        // 1. Scan the Backend (Java Microservices)
        sh "mvn sonar:sonar ${prParams} -Dsonar.host.url='${env.SONARQUBE_URL}' -Dsonar.token='${SONAR_TOKEN}'"
        
        // 2. Scan the Frontend (Angular)
        sh """
            mvn sonar:sonar -N ${prParams} \\
                -Dsonar.projectKey=safezone-frontend \\
                -Dsonar.projectName="SafeZone Frontend" \\
                -Dsonar.sources=buy-01-ui/src \\
                -Dsonar.tests=buy-01-ui/src \\
                -Dsonar.test.inclusions=**/*.spec.ts \\
                -Dsonar.coverage.exclusions=**/*.spec.ts,**/node_modules/**,**/dist/** \\
                -Dsonar.typescript.lcov.reportPaths=buy-01-ui/coverage/lcov.info \\
                -Dsonar.host.url='${env.SONARQUBE_URL}' \\
                -Dsonar.token='${SONAR_TOKEN}'
        """
    }
}
```

**Key changes:**
- Removed `if (params.SONAR_TOKEN_OVERRIDE?.trim())` check
- Removed `env.FINAL_SONAR_URL` → use `env.SONARQUBE_URL`
- Removed `env.FINAL_SONAR_TOKEN` → use `SONAR_TOKEN`
- Simplified to single credential source

---

### Change 2: Quality Gate Stage (~Line 267-290)

**Find:**
```groovy
// Load the token again since we're in a new stage
if (params.SONAR_TOKEN_OVERRIDE?.trim()) {
    ...
} else {
    withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN_VAR')]) {
        env.FINAL_SONAR_TOKEN = env.SONAR_TOKEN_VAR
        pollQualityGate(serverUrl, taskId)
    }
    return
}

pollQualityGate(serverUrl, taskId)
```

**Replace with:**
```groovy
// Load token from Jenkins credentials
withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
    pollQualityGate(serverUrl, taskId, SONAR_TOKEN)
}
```

---

### Change 3: Deploy Stage (~Line 391-497)

**Find the entire Deploy stage that starts with:**
```groovy
stage('Deploy') {
    when {
        allOf {
            expression { env.IS_PULL_REQUEST != "true" }
            expression { env.IS_MAIN_BRANCH == "true" }
        }
    }
    ...contains AWS deployment logic...
}
```

**Replace with:**
```groovy
stage('Deploy') {
    when {
        allOf {
            expression { env.IS_PULL_REQUEST != "true" }  // Skip deployment for PRs
            expression { env.IS_MAIN_BRANCH == "true" }  // Only deploy from main branch
        }
    }
    options {
        timeout(time: 30, unit: 'MINUTES')
    }
    steps {
        echo '=========================================='
        echo '🚀 Deploying locally via Docker Compose...'
        echo '=========================================='
        sh '''
            # Build Docker images
            ./.pipeline/jenkins/build-docker-images.sh ${BUILD_NUMBER}
            
            # Start services locally
            export MONGO_ROOT_USERNAME=${MONGO_ROOT_USERNAME}
            export MONGO_ROOT_PASSWORD=${MONGO_ROOT_PASSWORD}
            export API_GATEWAY_URL=${API_GATEWAY_URL}
            cd .pipeline && docker compose --file docker-compose.yml up -d && cd ..
        '''
        echo "✅ Local deployment successful!"
        echo ""
        echo "📋 Services Status:"
        sh "docker ps --filter 'name=buy-01' --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}'"
        echo ""
        echo "🌐 Access URLs:"
        echo "  Frontend: http://localhost:4200"
        echo "  API Gateway: http://localhost:8080"
        echo "  Eureka: http://localhost:8761"
        echo ""
    }
}
```

---

### Change 4: pollQualityGate Function (~Line 633-675)

**Find the function signature:**
```groovy
void pollQualityGate(String serverUrl, String taskId) {
```

**Change to include token parameter:**
```groovy
void pollQualityGate(String serverUrl, String taskId, String token) {
```

**Then update ALL references in the function:**
- Change `${env.FINAL_SONAR_TOKEN}` → `${token}`

**Find:**
```groovy
def taskStatus = sh(
    script: "curl -s -u '${env.FINAL_SONAR_TOKEN}:' '${serverUrl}/api/ce/task?id=${taskId}' ...",
```

**Replace with:**
```groovy
def taskStatus = sh(
    script: "curl -s -u '${token}:' '${serverUrl}/api/ce/task?id=${taskId}' ...",
```

Do this for ALL curl commands in the function (there are 3 occurrences).

---

## ✅ Verification

After making these changes:

1. **Check syntax:**
   ```bash
   # Jenkins will validate syntax when you save the job
   ```

2. **Look for these patterns - they should NOT exist:**
   - `params.SONAR_TOKEN_OVERRIDE`
   - `params.DEPLOYMENT_TARGET`
   - `env.FINAL_TARGET`
   - `env.FINAL_SONAR_URL`
   - `env.FINAL_SONAR_TOKEN`
   - `AWS_DEPLOY_HOST`
   - `AWS_DEPLOY_USER`
   - `AWS_SSH_KEY`

3. **These should exist:**
   - `env.SONARQUBE_URL` (not FINAL_SONAR_URL)
   - `SONAR_TOKEN` variable (from withCredentials)
   - Local Docker Compose deployment only

---

## 🚀 Quick Edit Method

1. Open Jenkinsfile in your editor
2. Use Find & Replace (Cmd+F / Ctrl+F):
   - Replace `${env.FINAL_SONAR_URL}` → `${env.SONARQUBE_URL}`
   - Replace `${env.FINAL_SONAR_TOKEN}` → `${SONAR_TOKEN}`
3. Manually do the 4 changes above
4. Save and test

**Estimated time:** 10 minutes

