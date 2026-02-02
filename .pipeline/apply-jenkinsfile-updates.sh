#!/bin/bash
# Apply Jenkinsfile changes using sed commands

set -e

JENKINSFILE="Jenkinsfile"
BACKUP="Jenkinsfile.pre-local-$(date +%Y%m%d-%H%M%S)"

echo "Creating backup: $BACKUP"
cp "$JENKINSFILE" "$BACKUP"

# Create a Python script to do the complex replacements
cat > /tmp/fix_jenkinsfile.py << 'EOF'
import sys
import re

def main():
    with open('Jenkinsfile', 'r') as f:
        content = f.read()
    
    # Change 1: Fix SonarQube Analysis - remove token override logic
    # Find and replace the entire if-else block
    pattern1 = r"// Load SonarQube token based on whether we're using override or Jenkins credentials\s+if \(params\.SONAR_TOKEN_OVERRIDE\?\.trim\(\)\) \{[^}]+withSonarQubeEnv\('SonarQube'\) \{[^}]+sh \"mvn sonar:sonar[^}]+\}\s+\} else \{\s+// Use Jenkins credential\s+echo \"🔑 Using SonarQube Token from Jenkins Credentials\"\s+withCredentials\(\[string\(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN_VAR'\)\]\) \{\s+env\.FINAL_SONAR_TOKEN = env\.SONAR_TOKEN_VAR\s+withSonarQubeEnv\('SonarQube'\) \{[^}]+\}\s+\}\s+\}"
    
    # This is too complex - let's do line-by-line processing
    lines = content.split('\n')
    new_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Detect and replace SonarQube token logic
        if "// Load SonarQube token based on whether we're using override" in line:
            # Skip old logic and insert new
            new_lines.append("                    ")
            new_lines.append("                    // Use Jenkins credential for SonarQube token")
            new_lines.append('                    echo "🔑 Using SonarQube Token from Jenkins Credentials"')
            new_lines.append("                    withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {")
            new_lines.append("                        withSonarQubeEnv('SonarQube') {")
            new_lines.append("                            // 1. Scan the Backend (Java Microservices)")
            new_lines.append("                            sh \"mvn sonar:sonar ${prParams} -Dsonar.host.url='${env.SONARQUBE_URL}' -Dsonar.token='${SONAR_TOKEN}'\"")
            new_lines.append("                            ")
            new_lines.append("                            // 2. Scan the Frontend (Angular)")
            new_lines.append('                            sh """')
            new_lines.append("                                mvn sonar:sonar -N ${prParams} \\\\")
            new_lines.append("                                    -Dsonar.projectKey=safezone-frontend \\\\")
            new_lines.append('                                    -Dsonar.projectName="SafeZone Frontend" \\\\')
            new_lines.append("                                    -Dsonar.sources=buy-01-ui/src \\\\")
            new_lines.append("                                    -Dsonar.tests=buy-01-ui/src \\\\")
            new_lines.append("                                    -Dsonar.test.inclusions=**/*.spec.ts \\\\")
            new_lines.append("                                    -Dsonar.coverage.exclusions=**/*.spec.ts,**/node_modules/**,**/dist/** \\\\")
            new_lines.append("                                    -Dsonar.typescript.lcov.reportPaths=buy-01-ui/coverage/lcov.info \\\\")
            new_lines.append("                                    -Dsonar.host.url='${env.SONARQUBE_URL}' \\\\")
            new_lines.append("                                    -Dsonar.token='${SONAR_TOKEN}'")
            new_lines.append('                            """')
            new_lines.append("                        }")
            new_lines.append("                    }")
            
            # Skip until end of old block
            i += 1
            brace_count = 0
            in_if = False
            while i < len(lines):
                if 'if (params.SONAR_TOKEN_OVERRIDE?.trim())' in lines[i]:
                    in_if = True
                if in_if:
                    brace_count += lines[i].count('{') - lines[i].count('}')
                    if brace_count <= 0 and '}' in lines[i]:
                        break
                i += 1
            i += 1
            continue
            
        # Fix Quality Gate token logic  
        elif "// Load the token again since we're in a new stage" in line:
            new_lines.append("                        // Load token from Jenkins credentials")
            new_lines.append("                        withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {")
            new_lines.append("                            pollQualityGate(serverUrl, taskId, SONAR_TOKEN)")
            new_lines.append("                        }")
            
            # Skip old logic
            i += 1
            while i < len(lines) and 'pollQualityGate(serverUrl, taskId)' not in lines[i]:
                i += 1
            i += 1
            continue
            
        # Fix Deploy stage
        elif line.strip() == "stage('Deploy') {" and i > 300:
            # This is the deploy stage
            new_lines.append("        stage('Deploy') {")
            i += 1
            # Skip to the 'when' block
            while i < len(lines) and 'when {' not in lines[i]:
                new_lines.append(lines[i])
                i += 1
            new_lines.append(lines[i])  # when {
            i += 1
            while i < len(lines) and '}' not in lines[i]:
                new_lines.append(lines[i])
                i += 1
            new_lines.append(lines[i])  # closing }
            i += 1
            
            # Add options and steps
            new_lines.append("            options {")
            new_lines.append("                timeout(time: 30, unit: 'MINUTES')")
            new_lines.append("            }")
            new_lines.append("            steps {")
            new_lines.append("                echo '=========================================='")
            new_lines.append("                echo '🚀 Deploying locally via Docker Compose...'")
            new_lines.append("                echo '=========================================='")
            new_lines.append("                sh '''")
            new_lines.append("                    # Build Docker images")
            new_lines.append("                    ./.pipeline/jenkins/build-docker-images.sh ${BUILD_NUMBER}")
            new_lines.append("                    ")
            new_lines.append("                    # Start services locally")
            new_lines.append("                    export MONGO_ROOT_USERNAME=${MONGO_ROOT_USERNAME}")
            new_lines.append("                    export MONGO_ROOT_PASSWORD=${MONGO_ROOT_PASSWORD}")
            new_lines.append("                    export API_GATEWAY_URL=${API_GATEWAY_URL}")
            new_lines.append("                    cd .pipeline && docker compose --file docker-compose.yml up -d && cd ..")
            new_lines.append("                '''")
            new_lines.append('                echo "✅ Local deployment successful!"')
            new_lines.append('                echo ""')
            new_lines.append('                echo "📋 Services Status:"')
            new_lines.append("                sh \"docker ps --filter 'name=buy-01' --format 'table {{.Names}}\\\\t{{.Status}}\\\\t{{.Ports}}'\"")
            new_lines.append('                echo ""')
            new_lines.append('                echo "🌐 Access URLs:"')
            new_lines.append('                echo "  Frontend: http://localhost:4200"')
            new_lines.append('                echo "  API Gateway: http://localhost:8080"')
            new_lines.append('                echo "  Eureka: http://localhost:8761"')
            new_lines.append('                echo ""')
            new_lines.append("            }")
            new_lines.append("        }")
            
            # Skip old deploy stage content
            while i < len(lines):
                if lines[i].strip() == '}' and i > 400:
                    # Check if this closes the Deploy stage
                    if i + 1 < len(lines) and 'post {' in lines[i + 1]:
                        i += 1
                        break
                i += 1
            continue
            
        else:
            # Replace variable references
            line = line.replace("${env.FINAL_SONAR_URL}", "${env.SONARQUBE_URL}")
            line = line.replace("${env.FINAL_SONAR_TOKEN}", "${SONAR_TOKEN}")
            line = line.replace("'${env.FINAL_SONAR_TOKEN}'", "'${token}'")
            new_lines.append(line)
        
        i += 1
    
    # Fix pollQualityGate function signature
    result = '\n'.join(new_lines)
    result = result.replace(
        "void pollQualityGate(String serverUrl, String taskId) {",
        "void pollQualityGate(String serverUrl, String taskId, String token) {"
    )
    
    with open('Jenkinsfile', 'w') as f:
        f.write(result)
    
    print("✅ Jenkinsfile updated successfully")

if __name__ == '__main__':
    main()
EOF

python3 /tmp/fix_jenkinsfile.py

echo ""
echo "✅ Jenkinsfile has been updated for local-only deployment"
echo ""
echo "Changes applied:"
echo "  ✅ SonarQube Analysis - removed token override logic"
echo "  ✅ Quality Gate - simplified token handling"  
echo "  ✅ Deploy stage - removed AWS, local Docker Compose only"
echo "  ✅ pollQualityGate - updated function signature"
echo ""
echo "Backup saved as: $BACKUP"
