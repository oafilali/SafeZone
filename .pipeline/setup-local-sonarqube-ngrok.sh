#!/bin/bash
# Script to set up local SonarQube and ngrok for SafeZone pipeline

set -e

SONARQUBE_PORT=9000
NGROK_BIN=$(command -v ngrok || true)
DOCKER_COMPOSE_BIN=$(command -v docker-compose || command -v docker compose || true)

# Check Docker
if ! command -v docker &> /dev/null; then
  echo "❌ Docker is not installed. Please install Docker first."
  exit 1
fi

# Check Docker Compose
if [ -z "$DOCKER_COMPOSE_BIN" ]; then
  echo "❌ Docker Compose is not installed. Please install Docker Compose."
  exit 1
fi

# Check ngrok
if [ -z "$NGROK_BIN" ]; then
  echo "🔍 ngrok not found. Installing ngrok..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install --cask ngrok
  else
    echo "Please install ngrok manually from https://ngrok.com/download"
    exit 1
  fi
  NGROK_BIN=$(command -v ngrok)
fi

echo "✅ ngrok found at $NGROK_BIN"

# Start SonarQube (if not running)
if ! docker ps --format '{{.Names}}' | grep -q 'buy01-sonarqube'; then
  echo "🚀 Starting SonarQube and dependencies via Docker Compose..."
  (cd "$(dirname "$0")" && $DOCKER_COMPOSE_BIN up -d sonarqube-db sonarqube)
else
  echo "✅ SonarQube is already running."
fi

# Wait for SonarQube to be healthy
SONARQUBE_HEALTH=""
echo "⏳ Waiting for SonarQube to be healthy..."
for i in {1..30}; do
  SONARQUBE_HEALTH=$(docker inspect --format='{{.State.Health.Status}}' buy01-sonarqube 2>/dev/null || echo "")
  if [ "$SONARQUBE_HEALTH" == "healthy" ]; then
    echo "✅ SonarQube is healthy."
    break
  fi
  sleep 3
done
if [ "$SONARQUBE_HEALTH" != "healthy" ]; then
  echo "⚠️ SonarQube did not become healthy in time. Check logs with: docker logs buy01-sonarqube"
fi

# Start ngrok (if not running)
if pgrep -f "ngrok.*$SONARQUBE_PORT" > /dev/null; then
  echo "✅ ngrok tunnel for port $SONARQUBE_PORT is already running."
else
  echo "🚀 Starting ngrok tunnel for SonarQube on port $SONARQUBE_PORT..."
  nohup $NGROK_BIN http $SONARQUBE_PORT > .ngrok-sonarqube.log 2>&1 &
  sleep 3
fi

# Show ngrok public URL
NGROK_API_URL="http://localhost:4040/api/tunnels"
NGROK_URL=$(curl -s $NGROK_API_URL | grep -Eo 'https://[a-zA-Z0-9\-]+\.ngrok-free\.dev' | head -n1)
if [ -n "$NGROK_URL" ]; then
  echo "🌐 ngrok public URL for SonarQube: $NGROK_URL"
  echo "Copy this URL and use it as the SONARQUBE_URL_OVERRIDE in your Jenkins pipeline."
else
  echo "⚠️ Could not retrieve ngrok public URL. Check ngrok status with: $NGROK_BIN status"
fi

echo "✅ Local SonarQube and ngrok setup complete."