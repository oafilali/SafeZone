#!/bin/bash

################################################################################
# Pipeline Infrastructure Stop Script
# Stops all pipeline services (Jenkins, SonarQube, PostgreSQL, ngrok)
#
# USAGE:
#   ./stop_pipeline.sh [OPTIONS]
#
# OPTIONS:
#   --help              Show this help message
#   --cleanup           Also remove volumes and reset all data
#   --force             Force stop containers (no graceful shutdown)
#
# NOTE: This script gracefully stops containers and preserves data by default
#
################################################################################

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="${PROJECT_ROOT}/.pipeline/stop.log"

# Parse command line arguments
CLEANUP=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --cleanup) CLEANUP=true; shift ;;
        --force) FORCE=true; shift ;;
        --help) show_help; exit 0 ;;
        *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

# Helper functions
show_help() {
    grep "^#" "$0" | grep -E "^# " | sed 's/^# //'
}

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}❌ ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

section() {
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════${NC}"
}

# Initialize log
: > "$LOG_FILE"
log "Pipeline Infrastructure Stop started"
log "Options: CLEANUP=$CLEANUP, FORCE=$FORCE"

section "STOPPING PIPELINE SERVICES"

# Stop ngrok
log "Stopping ngrok tunnel..."
if pkill -f "ngrok.*http.*8088" 2>/dev/null; then
    rm -f /tmp/ngrok.pid 2>/dev/null || true
    success "ngrok stopped"
else
    warning "ngrok was not running"
fi

# Stop Docker containers
log "Stopping Docker containers..."

CONTAINERS=("jenkins-local" "sonarqube" "sonarqube-db")
STOPPED=0

for CONTAINER in "${CONTAINERS[@]}"; do
    if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER}$"; then
        log "  Stopping $CONTAINER..."
        
        if [ "$FORCE" = true ]; then
            if docker stop -t 0 "$CONTAINER" > /dev/null 2>&1; then
                success "  $CONTAINER stopped (forced)"
                ((STOPPED++))
            else
                warning "  Failed to force stop $CONTAINER"
            fi
        else
            if docker stop -t 30 "$CONTAINER" > /dev/null 2>&1; then
                success "  $CONTAINER stopped"
                ((STOPPED++))
            else
                warning "  Failed to stop $CONTAINER (trying force stop)"
                if docker stop -t 0 "$CONTAINER" > /dev/null 2>&1; then
                    success "  $CONTAINER stopped (force)"
                    ((STOPPED++))
                else
                    error "  Could not stop $CONTAINER"
                fi
            fi
        fi
    else
        log "  $CONTAINER not running"
    fi
done

if [ $STOPPED -gt 0 ]; then
    success "Stopped $STOPPED container(s)"
else
    warning "No containers were running"
fi

# Cleanup if requested
if [ "$CLEANUP" = true ]; then
    section "CLEANUP"
    
    log "Removing Docker containers..."
    for CONTAINER in "${CONTAINERS[@]}"; do
        if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER}$"; then
            if docker rm -f "$CONTAINER" > /dev/null 2>&1; then
                success "  Removed container: $CONTAINER"
            fi
        fi
    done
    
    log "Removing Docker volumes..."
    if docker volume rm jenkins_home 2>/dev/null; then
        success "  Removed volume: jenkins_home"
    else
        warning "  Volume jenkins_home not found"
    fi
    
    log "Pruning Docker system..."
    docker system prune -f >> "$LOG_FILE" 2>&1 || true
    success "  Docker cleanup completed"
fi

echo ""
section "STOP COMPLETE"

if [ "$CLEANUP" = false ]; then
    echo -e "${YELLOW}Data preserved. To restart:${NC}"
    echo -e "${GREEN}  ./boot-pipeline.sh${NC}"
    echo ""
    echo -e "${YELLOW}To remove all data and containers:${NC}"
    echo -e "${GREEN}  ./stop_pipeline.sh --cleanup${NC}"
else
    echo -e "${YELLOW}All data and containers removed. To start fresh:${NC}"
    echo -e "${GREEN}  ./boot-pipeline.sh${NC}"
fi

echo ""
success "All services stopped successfully"
echo ""
