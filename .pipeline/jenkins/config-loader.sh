# Deployment Configuration
# Source this file before running deployment scripts

# AWS Configuration - REQUIRED, no fallbacks
export AWS_DEPLOY_HOST="${AWS_DEPLOY_HOST:?AWS_DEPLOY_HOST must be set}"
export AWS_DEPLOY_USER="${AWS_DEPLOY_USER:?AWS_DEPLOY_USER must be set}"
export AWS_DEPLOY_PATH="/home/${AWS_DEPLOY_USER}/buy-01-app"

# SSH Key Location - REQUIRED
export AWS_SSH_KEY="${AWS_SSH_KEY:?AWS_SSH_KEY must be set - configure in Jenkins credentials or set environment variable}"

# MongoDB Credentials - REQUIRED
export MONGO_ROOT_USERNAME="${MONGO_ROOT_USERNAME:?MONGO_ROOT_USERNAME must be set}"
export MONGO_ROOT_PASSWORD="${MONGO_ROOT_PASSWORD:?MONGO_ROOT_PASSWORD must be set}"

# API URLs - REQUIRED
export API_GATEWAY_URL="${API_GATEWAY_URL:?API_GATEWAY_URL must be set}"

# Validate SSH key exists
if [ ! -f "$AWS_SSH_KEY" ]; then
    echo "❌ Error: SSH key not found at $AWS_SSH_KEY"
    echo "Please configure AWS_SSH_KEY environment variable or Jenkins credential"
    exit 1
fi
