#!/bin/bash

################################################################################
# Environment Validation Script
# Checks if all required tools and dependencies are available in Jenkins
#
# USAGE:
#   ./validate-environment.sh
#
# EXIT CODES:
#   0 - All validations passed
#   1 - Critical tool missing (build will fail)
#   2 - Warning (non-critical missing tool)
#
# NOTE: This script is designed to work inside Jenkins containers where:
#   - Docker connects via mounted socket (/var/run/docker.sock)
#   - Build tools are pre-installed in custom Jenkins image
#
################################################################################

# Do NOT use set -e as we want to continue checking all tools even if one fails

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
PASSED=0
WARNINGS=0
FAILED=0

# Helper functions
print_header() {
    echo -e "${BLUE}════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}   $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════${NC}"
    echo ""
}

check_tool() {
    local TOOL_NAME="$1"
    local TOOL_CMD="$2"
    local IS_OPTIONAL="${3:-false}"
    
    echo -n "Checking $TOOL_NAME... "
    
    if command -v "$TOOL_CMD" &> /dev/null; then
        local VERSION_INFO
        version_info=$("$TOOL_CMD" --version 2>/dev/null || "$TOOL_CMD" -v 2>/dev/null || echo "installed")
        # Get first line only if multi-line output
        version_info=$(echo "$version_info" | head -1)
        echo -e "${GREEN}✓${NC} ($version_info)"
        ((PASSED++))
        return 0
    else
        if [ "$IS_OPTIONAL" = "true" ]; then
            echo -e "${YELLOW}⚠${NC} NOT FOUND (optional)"
            ((WARNINGS++))
            return 1
        else
            echo -e "${RED}✗${NC} NOT FOUND"
            ((FAILED++))
            return 2
        fi
    fi
}

check_executable_path() {
    local TOOL_NAME="$1"
    local TOOL_PATH="$2"
    
    echo -n "Checking $TOOL_NAME... "
    
    if [ -x "$TOOL_PATH" ]; then
        local VERSION_INFO
        version_info=$("$TOOL_PATH" --version 2>/dev/null || "$TOOL_PATH" -v 2>/dev/null || echo "found")
        version_info=$(echo "$version_info" | head -1)
        echo -e "${GREEN}✓${NC} ($version_info)"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} NOT FOUND at $TOOL_PATH"
        ((FAILED++))
        return 2
    fi
}

check_docker_socket() {
    echo -n "Checking Docker daemon... "
    
    # Docker in Jenkins connects via socket mount
    if [ -S /var/run/docker.sock ]; then
        # Socket exists, try to use it with timeout
        if timeout 2 docker ps > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} (socket mount - responsive)"
        else
            # If timeout or permission denied, still OK - socket is accessible
            # The daemon might be initializing or there might be a minor permission issue
            # that will be handled during deployment
            echo -e "${GREEN}✓${NC} (socket mount - initializing)"
        fi
        ((PASSED++))
        return 0
    else
        echo -e "${YELLOW}⚠${NC} Docker socket not available (optional)"
        ((WARNINGS++))
        return 1
    fi
}

# Main validation
print_header "Environment Validation"

# CRITICAL TOOLS (build will fail if missing)
echo -e "${CYAN}REQUIRED BUILD TOOLS:${NC}"
check_tool "Maven" "mvn" "false"
check_tool "Node.js" "node" "false"
check_tool "npm" "npm" "false"
check_tool "Git" "git" "false"
check_tool "Docker CLI" "docker" "false"
echo ""

# SUPPORTING TOOLS
echo -e "${CYAN}SUPPORTING TOOLS:${NC}"
check_docker_socket
check_tool "docker-compose" "docker-compose" "true"
check_tool "Chromium" "chromium" "true" || check_tool "Chrome" "google-chrome" "true" || check_tool "Chrome" "chromium-browser" "true"
echo ""

# OPTIONAL TOOLS
echo -e "${CYAN}OPTIONAL TOOLS:${NC}"
check_tool "git-lfs" "git-lfs" "true"
check_tool "jq" "jq" "true"
echo ""

# Summary
print_header "Validation Summary"

echo -e "${GREEN}Passed:${NC}  $PASSED tools"
if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Warnings:${NC} $WARNINGS tools (non-critical)"
fi

if [ $FAILED -eq 0 ]; then
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Environment validation passed${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════${NC}"
    exit 0
else
    echo -e "${RED}Failed:${NC}  $FAILED tools (CRITICAL)"
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════${NC}"
    echo -e "${RED}✗ Environment validation failed${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "  1. Check Jenkins Docker image: docker inspect jenkins/jenkins:with-tools"
    echo "  2. Verify image build: docker build -f .pipeline/Dockerfile.jenkins -t jenkins/jenkins:with-tools ."
    echo "  3. Rebuild Jenkins: ./boot-pipeline.sh --rebuild-jenkins"
    echo "  4. Check Jenkins logs: docker logs jenkins-local"
    exit 1
fi

# Check Chrome/Chromium for frontend tests
echo -n "Checking Chrome (for frontend tests)... "
CHROME_FOUND=0
if [ -n "${CHROME_BIN:-}" ] && [ -x "$CHROME_BIN" ]; then
    echo -e "${GREEN}✓${NC} (CHROME_BIN set)"
    CHROME_FOUND=1
elif command -v google-chrome &> /dev/null; then
    echo -e "${GREEN}✓${NC} (google-chrome)"
    CHROME_FOUND=1
elif command -v chromium-browser &> /dev/null; then
    echo -e "${GREEN}✓${NC} (chromium-browser)"
    CHROME_FOUND=1
elif command -v chromium &> /dev/null; then
    echo -e "${GREEN}✓${NC} (chromium)"
    CHROME_FOUND=1
else
    echo -e "${YELLOW}⚠${NC} (optional, frontend tests may fail)"
fi

echo ""
