#!/bin/bash

#############################################################
# Pipeline Infrastructure Boot Script
# Starts Jenkins, SonarQube, PostgreSQL, and ngrok
# Use this to get the CI/CD pipeline ready after restart
#############################################################

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   Pipeline Infrastructure Boot${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check Docker is running
echo -e "${YELLOW}[1/4] Checking Docker daemon...${NC}"
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running!${NC}"
    echo -e "${YELLOW}Please start Docker Desktop or docker daemon${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is running${NC}"
echo ""

# Start SonarQube + Database
echo -e "${YELLOW}[2/4] Starting SonarQube (with PostgreSQL)...${NC}"
cd "$PROJECT_ROOT/.pipeline"

# Start only SonarQube infrastructure (sonarqube-db and sonarqube)
docker compose up -d sonarqube-db sonarqube

# Wait for SonarQube to be ready
echo -e "${YELLOW}Waiting for SonarQube to start (this takes ~30 seconds)...${NC}"
sleep 30

# Check if SonarQube is responding
max_attempts=10
attempt=1
while [ $attempt -le $max_attempts ]; do
    if curl -s http://localhost:9000/api/system/health | grep -q '"health":"UP"'; then
        echo -e "${GREEN}✓ SonarQube is ready${NC}"
        break
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        echo -e "${YELLOW}⚠️  SonarQube taking longer than expected${NC}"
        echo -e "${YELLOW}   Check with: docker logs buy01-sonarqube${NC}"
    else
        echo -e "${YELLOW}  Attempt $attempt/$max_attempts - waiting...${NC}"
        sleep 3
    fi
    
    attempt=$((attempt + 1))
done

echo -e "${GREEN}  URL: http://localhost:9000${NC}"
echo -e "${GREEN}  Credentials: admin/admin${NC}"
echo ""

# Start Jenkins
echo -e "${YELLOW}[3/4] Starting Jenkins...${NC}"

# Build custom Jenkins image if it doesn't exist
if ! docker image inspect jenkins/jenkins:with-tools > /dev/null 2>&1; then
    echo -e "${YELLOW}  Building custom Jenkins image with Maven, Node.js, and Docker...${NC}"
    docker build -f ./.pipeline/Dockerfile.jenkins -t jenkins/jenkins:with-tools . > /dev/null 2>&1 || true
fi

# Check if jenkins-local container exists
if docker ps -a --format '{{.Names}}' | grep -q '^jenkins-local$'; then
    echo -e "${YELLOW}  Jenkins container found, starting...${NC}"
    docker start jenkins-local > /dev/null 2>&1 || true
else
    echo -e "${YELLOW}  Jenkins container not found, creating...${NC}"
    docker run -d \
        --name jenkins-local \
        -p 8088:8080 \
        -p 50000:50000 \
        -v jenkins_home:/var/jenkins_home \
        -v /var/run/docker.sock:/var/run/docker.sock \
        jenkins/jenkins:with-tools > /dev/null 2>&1 || true
fi

echo -e "${YELLOW}Waiting for Jenkins to start...${NC}"
sleep 10

# Check if Jenkins is responding
max_attempts=30
attempt=1
while [ $attempt -le $max_attempts ]; do
    if curl -s http://localhost:8088/api/json > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Jenkins is ready${NC}"
        break
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        echo -e "${YELLOW}⚠️  Jenkins taking longer than expected${NC}"
        echo -e "${YELLOW}   Check with: docker logs jenkins-local${NC}"
    else
        echo -e "${YELLOW}  Attempt $attempt/$max_attempts - waiting...${NC}"
        sleep 2
    fi
    
    attempt=$((attempt + 1))
done

echo -e "${GREEN}  URL: http://localhost:8088${NC}"
echo ""

# Start ngrok tunnel
echo -e "${YELLOW}[4/4] Starting ngrok tunnel for GitHub webhooks...${NC}"

# Kill any existing ngrok processes
pkill -f "ngrok.*8088" > /dev/null 2>&1 || true
sleep 1

# Start ngrok in background
ngrok http 8088 > /tmp/ngrok.log 2>&1 &
NGROK_PID=$!
echo "$NGROK_PID" > /tmp/ngrok.pid

echo -e "${YELLOW}Waiting for ngrok to establish tunnel...${NC}"
sleep 5

# Extract ngrok URL
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$NGROK_URL" ]; then
    echo -e "${RED}❌ Failed to get ngrok tunnel URL${NC}"
    echo -e "${YELLOW}Check ngrok status with: cat /tmp/ngrok.log${NC}"
else
    echo -e "${GREEN}✓ ngrok tunnel established${NC}"
    echo -e "${GREEN}  Public URL: $NGROK_URL${NC}"
    echo -e "${YELLOW}  Update GitHub webhook payload URL to:${NC}"
    echo -e "${YELLOW}  $NGROK_URL/github-webhook/{{NC}"
fi

cd "$PROJECT_ROOT"
echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}✓ Pipeline Infrastructure is Ready!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${BLUE}Quick Links:${NC}"
echo -e "  Jenkins:    ${GREEN}http://localhost:8088${NC}"
echo -e "  SonarQube:  ${GREEN}http://localhost:9000${NC}"
echo -e "  ngrok:      ${GREEN}http://localhost:4040${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo -e "  1. Push to 'antigravity' or 'main' branch to trigger builds"
echo -e "  2. Monitor Jenkins console: http://localhost:8088/queue/"
echo -e "  3. View SonarQube analysis: http://localhost:9000/projects"
echo ""
echo -e "${YELLOW}To stop everything: ./stop_pipeline.sh${NC}"
echo ""
