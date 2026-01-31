#!/bin/bash
# Master setup script for SafeZone Local CI/CD Pipeline
# This script sets up Jenkins, SonarQube, ngrok, and all dependencies locally on macOS

set -e

echo "=========================================="
echo "🚀 SafeZone Local Pipeline Setup"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Change to script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS. For other platforms, please install dependencies manually."
    exit 1
fi

# Check prerequisites
echo ""
echo "=========================================="
echo "📋 Checking Prerequisites"
echo "=========================================="

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    print_warning "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    print_success "Homebrew installed"
else
    print_success "Homebrew found"
fi

# Check for Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker not found. Please install Docker Desktop from https://www.docker.com/products/docker-desktop"
    exit 1
else
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        print_error "Docker is installed but not running. Please start Docker Desktop."
        exit 1
    fi
    print_success "Docker is installed and running"
fi

# Install Java (required for Jenkins and Maven)
echo ""
echo "=========================================="
echo "☕ Installing Java 17"
echo "=========================================="
if ! command -v java &> /dev/null; then
    brew install openjdk@17
    # Add to PATH
    echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
    export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
    print_success "Java 17 installed"
else
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
    if [ "$JAVA_VERSION" -ge 17 ]; then
        print_success "Java $JAVA_VERSION is already installed"
    else
        print_warning "Java version is older than 17. Installing Java 17..."
        brew install openjdk@17
    fi
fi

# Install Maven
echo ""
echo "=========================================="
echo "📦 Installing Maven"
echo "=========================================="
if ! command -v mvn &> /dev/null; then
    brew install maven
    print_success "Maven installed"
else
    print_success "Maven is already installed ($(mvn -version | head -n 1))"
fi

# Install Node.js and npm
echo ""
echo "=========================================="
echo "📦 Installing Node.js"
echo "=========================================="
if ! command -v node &> /dev/null; then
    brew install node@20
    print_success "Node.js 20 installed"
else
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -ge 18 ]; then
        print_success "Node.js $NODE_VERSION is already installed"
    else
        print_warning "Node.js version is older than 18. Installing Node.js 20..."
        brew install node@20
    fi
fi

# Install Angular CLI
echo ""
echo "=========================================="
echo "📦 Installing Angular CLI"
echo "=========================================="
if ! command -v ng &> /dev/null; then
    npm install -g @angular/cli
    print_success "Angular CLI installed"
else
    print_success "Angular CLI is already installed"
fi

# Install ngrok
echo ""
echo "=========================================="
echo "🌐 Installing ngrok"
echo "=========================================="
if ! command -v ngrok &> /dev/null; then
    brew install ngrok/ngrok/ngrok
    print_success "ngrok installed"
    print_info "You may need to authenticate ngrok with your account"
    print_info "Run: ngrok config add-authtoken <YOUR_TOKEN>"
    print_info "Get your token from: https://dashboard.ngrok.com/get-started/your-authtoken"
else
    print_success "ngrok is already installed"
fi

# Install Jenkins
echo ""
echo "=========================================="
echo "🔧 Installing Jenkins"
echo "=========================================="
if ! brew list jenkins-lts &> /dev/null; then
    brew install jenkins-lts
    print_success "Jenkins LTS installed"
else
    print_success "Jenkins is already installed"
fi

# Start Jenkins service
echo ""
echo "=========================================="
echo "🚀 Starting Jenkins Service"
echo "=========================================="
if brew services list | grep jenkins-lts | grep started &> /dev/null; then
    print_info "Jenkins is already running"
else
    brew services start jenkins-lts
    print_success "Jenkins service started"
    print_info "Waiting for Jenkins to initialize (this may take 1-2 minutes)..."
    sleep 30
fi

# Wait for Jenkins to be ready
JENKINS_URL="http://localhost:8080"
MAX_WAIT=120
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if curl -s "$JENKINS_URL" > /dev/null 2>&1; then
        print_success "Jenkins is ready at $JENKINS_URL"
        break
    fi
    sleep 5
    WAITED=$((WAITED + 5))
    echo -n "."
done

if [ $WAITED -ge $MAX_WAIT ]; then
    print_warning "Jenkins is taking longer than expected to start"
    print_info "You can check Jenkins status with: brew services list"
fi

# Get Jenkins initial admin password
echo ""
echo "=========================================="
echo "🔑 Jenkins Initial Setup"
echo "=========================================="
JENKINS_SECRET_FILE="/opt/homebrew/var/jenkins_home/secrets/initialAdminPassword"
if [ -f "$JENKINS_SECRET_FILE" ]; then
    JENKINS_PASSWORD=$(cat "$JENKINS_SECRET_FILE")
    print_info "Jenkins Initial Admin Password: $JENKINS_PASSWORD"
    print_warning "SAVE THIS PASSWORD! You'll need it to complete Jenkins setup."
else
    print_warning "Could not find Jenkins initial admin password file"
    print_info "Check manually at: $JENKINS_SECRET_FILE"
fi

# Start SonarQube
echo ""
echo "=========================================="
echo "🔍 Starting SonarQube"
echo "=========================================="
print_info "Starting SonarQube via Docker Compose..."
./setup-sonarqube.sh

# Setup ngrok for Jenkins webhooks
echo ""
echo "=========================================="
echo "🌐 Setting up ngrok for GitHub Webhooks"
echo "=========================================="
print_info "Starting ngrok tunnel to Jenkins..."
./setup-jenkins-webhooks.sh

echo ""
echo "=========================================="
echo "✅ Local Pipeline Setup Complete!"
echo "=========================================="
echo ""
print_success "All components installed and started successfully!"
echo ""
echo "📋 Next Steps:"
echo "   1. Open Jenkins: $JENKINS_URL"
echo "   2. Complete Jenkins initial setup wizard"
echo "   3. Run the Jenkins configuration script:"
echo "      ./setup-local-jenkins.sh"
echo "   4. Configure GitHub webhook with the ngrok URL displayed above"
echo "   5. Update Jenkins credentials with your actual values"
echo ""
echo "📖 For detailed instructions, see README-local-pipeline.md"
echo ""
print_info "Jenkins Home: /opt/homebrew/var/jenkins_home"
print_info "SonarQube: http://localhost:9000"
print_info "Jenkins: http://localhost:8080"
echo ""
