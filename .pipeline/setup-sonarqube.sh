#!/bin/bash
# Script to set up local SonarQube for SafeZone pipeline
# No ngrok needed since Jenkins is now local

set -e

SONARQUBE_PORT=9000
DOCKER_COMPOSE_BIN=$(command -v docker-compose || command -v docker compose || true)

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

echo "=========================================="
echo "🔍 Starting Local SonarQube"
echo "=========================================="
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_error "Docker is not running. Please start Docker Desktop."
    exit 1
fi

print_success "Docker is running"

# Check Docker Compose
if [ -z "$DOCKER_COMPOSE_BIN" ]; then
    print_error "Docker Compose is not installed. Please install Docker Compose."
    exit 1
fi

print_success "Docker Compose found"

# Start SonarQube (if not running)
if ! docker ps --format '{{.Names}}' | grep -q 'buy01-sonarqube'; then
    print_info "Starting SonarQube and database via Docker Compose..."
    (cd "$(dirname "$0")" && $DOCKER_COMPOSE_BIN up -d sonarqube-db sonarqube)
    print_success "SonarQube services started"
else
    print_success "SonarQube is already running"
fi

# Wait for SonarQube to be healthy
print_info "Waiting for SonarQube to be healthy..."
SONARQUBE_HEALTH=""
for i in {1..60}; do
    SONARQUBE_HEALTH=$(docker inspect --format='{{.State.Health.Status}}' buy01-sonarqube 2>/dev/null || echo "")
    if [ "$SONARQUBE_HEALTH" == "healthy" ]; then
        print_success "SonarQube is healthy"
        break
    fi
    sleep 3
    echo -n "."
done

echo ""

if [ "$SONARQUBE_HEALTH" != "healthy" ]; then
    print_warning "SonarQube did not become healthy yet, but may still be initializing"
    print_info "First-time startup can take 2-3 minutes"
    print_info "Check logs with: docker logs buy01-sonarqube"
fi

echo ""
echo "=========================================="
print_success "SonarQube Setup Complete"
echo "=========================================="
echo ""
echo "  🔍 SonarQube URL: http://localhost:$SONARQUBE_PORT"
echo "  👤 Default Login: admin / admin"
echo ""
print_warning "IMPORTANT: Change default password on first login!"
echo ""
print_info "Next steps:"
echo "  1. Open http://localhost:9000 in your browser"
echo "  2. Login with admin/admin"
echo "  3. Change the password when prompted"
echo "  4. Go to My Account → Security → Generate Token"
echo "  5. Save the token and add it to Jenkins credentials as 'sonarqube-token'"
echo ""
print_info "To stop SonarQube:"
echo "  cd .pipeline && docker-compose stop sonarqube sonarqube-db"
echo ""
