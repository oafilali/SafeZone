#!/bin/bash
# Setup ngrok tunnel for GitHub webhooks to local Jenkins

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

JENKINS_PORT=8080
NGROK_BIN=$(command -v ngrok || true)

echo "=========================================="
echo "🌐 Setting up ngrok for Jenkins Webhooks"
echo "=========================================="
echo ""

# Check if ngrok is installed
if [ -z "$NGROK_BIN" ]; then
    echo "❌ ngrok is not installed. Installing..."
    brew install ngrok/ngrok/ngrok
    NGROK_BIN=$(command -v ngrok)
fi

print_success "ngrok found at $NGROK_BIN"

# Check if ngrok is already running for Jenkins
if pgrep -f "ngrok.*$JENKINS_PORT" > /dev/null; then
    print_info "ngrok tunnel for Jenkins is already running"
else
    print_info "Starting ngrok tunnel for Jenkins on port $JENKINS_PORT..."
    
    # Start ngrok in the background
    nohup $NGROK_BIN http $JENKINS_PORT > .ngrok-jenkins.log 2>&1 &
    
    print_info "Waiting for ngrok to initialize..."
    sleep 3
fi

# Get the ngrok public URL
NGROK_API_URL="http://localhost:4040/api/tunnels"
NGROK_URL=$(curl -s $NGROK_API_URL | grep -Eo 'https://[a-zA-Z0-9\-]+\.ngrok-free\.app' | head -n1)

if [ -n "$NGROK_URL" ]; then
    echo ""
    echo "=========================================="
    print_success "ngrok tunnel is active!"
    echo "=========================================="
    echo ""
    echo "  🌐 Jenkins Public URL: $NGROK_URL"
    echo "  🔗 Jenkins Local URL:  http://localhost:$JENKINS_PORT"
    echo ""
    echo "=========================================="
    echo "📋 GitHub Webhook Configuration"
    echo "=========================================="
    echo ""
    echo "1. Go to your GitHub repository settings:"
    echo "   https://github.com/YOUR_USERNAME/SafeZone/settings/hooks"
    echo ""
    echo "2. Click 'Add webhook'"
    echo ""
    echo "3. Configure the webhook:"
    echo "   Payload URL: ${NGROK_URL}/github-webhook/"
    echo "   Content type: application/json"
    echo "   Secret: (leave empty or set one)"
    echo "   Events: Just the push event"
    echo "   Active: ✓ checked"
    echo ""
    echo "4. Click 'Add webhook'"
    echo ""
    echo "=========================================="
    print_warning "IMPORTANT: ngrok tunnel will stay active until you stop it"
    print_info "To stop ngrok: pkill -f 'ngrok.*$JENKINS_PORT'"
    print_info "To view ngrok dashboard: http://localhost:4040"
    echo ""
else
    print_warning "Could not retrieve ngrok public URL"
    print_info "Check ngrok status at: http://localhost:4040"
    print_info "Or check logs: cat .ngrok-jenkins.log"
fi
