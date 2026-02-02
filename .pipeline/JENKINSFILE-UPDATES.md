# Jenkinsfile Updates for Local Pipeline...

This document lists the specific changes needed to update the Jenkinsfile for local-only deployment.

## Changes Required

### 1. SonarQube Analysis Stage (Lines 194-250)

**Replace** the entire if-else block for token override with:

```groovy
                    // Prepare PR-specific parameters if this is a pull request
                    def prParams = ""
                    if (env.IS_PULL_REQUEST == "true") {
                        prParams = "-Dsonar.pullrequest.key=${env.CHANGE_ID} -Dsonar.pullrequest.branch=${env.SOURCE_BRANCH} -Dsonar.pullrequest.base=${env.TARGET_BRANCH}"
                        echo "📝 Configuring PR analysis for pull request #${env.CHANGE_ID}"
                    }
                    
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

### 2. Quality Gate Stage (Lines 280-292)

**Replace** the token loading logic with:

```groovy
                        // Load token from Jenkins credentials
                        withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                            pollQualityGate(serverUrl, taskId, SONAR_TOKEN)
                        }
```

### 3. Deploy Stage (Lines 391-497)

**Replace** the entire Deploy stage with:

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

### 4. Poll Quality Gate Function (end of file, around line 656-698)

**Replace** the function signature to accept token parameter:

```groovy
// Helper function to poll SonarQube Quality Gate with token authentication
void pollQualityGate(String serverUrl, String taskId, String token) {
    // 1. Poll for Task Completion
    timeout(time: 5, unit: 'MINUTES') {
        waitUntil {
            script {
                // Use curl with the token
                def taskStatus = sh(
                    script: "curl -s -u '${token}:' '${serverUrl}/api/ce/task?id=${taskId}' | grep -o '\\\"status\\\":\\\"[^\\\"]*\\\"' | cut -d: -f2 | tr -d '\\\"'",
                    returnStdout: true
                ).trim()
                
                echo "Current Task Status: ${taskStatus}"
                return (taskStatus == 'SUCCESS' || taskStatus == 'FAILED' || taskStatus == 'CANCELED')
            }
        }
    }
    
    // 2. Poll for Quality Gate Status
    def analysisId = sh(
        script: "curl -s -u '${token}:' '${serverUrl}/api/ce/task?id=${taskId}' | grep -o '\\\"analysisId\\\":\\\"[^\\\"]*\\\"' | cut -d: -f2 | tr -d '\\\"'",
        returnStdout: true
    ).trim()
    
    if (analysisId) {
        // Extract only the first status (project status), ignoring condition statuses
        def qgStatus = sh(
            script: "curl -s -u '${token}:' '${serverUrl}/api/qualitygates/project_status?analysisId=${analysisId}' | grep -o '\\\"status\\\":\\\"[^\\\"]*\\\"' | head -n 1 | cut -d: -f2 | tr -d '\\\"'",
            returnStdout: true
        ).trim()
        
        echo "Quality Gate Status: ${qgStatus}"
        
        if (qgStatus != 'OK') {
            error "❌ Quality Gate FAILED: ${qgStatus}"
        } else {
            echo "✅ Quality Gate passed!"
        }
    } else {
        echo "⚠️ Could not retrieve Analysis ID via manual check."
    }
}
```

## Summary of Changes

- **Removed**: AWS deployment target parameter and logic
- **Removed**: SonarQube URL override parameter (always use localhost:9000)
- **Removed**: SonarQube token override logic
- **Removed**: All AWS deployment code (SSH, SCP, AWS credentials)
- **Updated**: Tool paths to use Homebrew (macOS) locations
- **Simplified**: Deploy stage to local Docker Compose only
- **Fixed**: Poll Quality Gate function to accept token parameter

## After Making These Changes

1. Commit the updated Jenkinsfile
2. Run the setup scripts
3. Configure Jenkins with the updated job
4. Test the pipeline with a test branch
