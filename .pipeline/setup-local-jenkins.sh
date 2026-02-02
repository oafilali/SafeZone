#!/bin/bash
# Setup script for local Jenkins configuration
# This script installs required plugins, configures credentials, and creates the pipeline job

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

echo "=========================================="
echo "🔧 Jenkins Configuration Setup"
echo "=========================================="
echo ""

JENKINS_URL="http://localhost:8080"
JENKINS_HOME="/opt/homebrew/var/jenkins_home"

# Check if Jenkins is running
if ! curl -s "$JENKINS_URL" > /dev/null 2>&1; then
    print_error "Jenkins is not running. Please start Jenkins first:"
    echo "   brew services start jenkins-lts"
    exit 1
fi

print_success "Jenkins is running at $JENKINS_URL"

# Check if Jenkins CLI is available
JENKINS_CLI="$JENKINS_HOME/war/WEB-INF/jenkins-cli.jar"
if [ ! -f "$JENKINS_CLI" ]; then
    print_info "Downloading Jenkins CLI..."
    curl -s -o /tmp/jenkins-cli.jar "$JENKINS_URL/jnlpJars/jenkins-cli.jar"
    JENKINS_CLI="/tmp/jenkins-cli.jar"
fi

# Function to run Jenkins CLI commands
jenkins_cli() {
    java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth admin:"${JENKINS_PASSWORD}" "$@"
}

# Prompt for Jenkins credentials
echo ""
print_info "Please provide your Jenkins admin credentials"
read -p "Jenkins Username [admin]: " JENKINS_USER
JENKINS_USER=${JENKINS_USER:-admin}

read -sp "Jenkins Password: " JENKINS_PASSWORD
echo ""

# Test authentication
if ! jenkins_cli who-am-i &> /dev/null; then
    print_error "Authentication failed. Please check your credentials."
    print_info "You can find the initial admin password at:"
    echo "   cat /opt/homebrew/var/jenkins_home/secrets/initialAdminPassword"
    exit 1
fi

print_success "Authentication successful"

# Install required plugins
echo ""
print_info "Installing required Jenkins plugins..."
PLUGINS=(
    "git"
    "github"
    "workflow-aggregator"
    "pipeline-github-lib"
    "sonar"
    "docker-workflow"
    "docker-plugin"
    "credentials-binding"
    "configuration-as-code"
    "job-dsl"
    "email-ext"
    "junit"
    "jacoco"
    "htmlpublisher"
)

for plugin in "${PLUGINS[@]}"; do
    print_info "Installing plugin: $plugin"
    jenkins_cli install-plugin "$plugin" || print_warning "Plugin $plugin may already be installed"
done

print_success "Plugins installation complete"

# Restart Jenkins to load plugins
print_info "Restarting Jenkins to load plugins..."
jenkins_cli safe-restart || print_warning "Jenkins restart initiated"
print_info "Waiting for Jenkins to restart (30 seconds)..."
sleep 30

# Wait for Jenkins to be ready
MAX_WAIT=120
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if curl -s "$JENKINS_URL" > /dev/null 2>&1; then
        print_success "Jenkins is ready"
        break
    fi
    sleep 5
    WAITED=$((WAITED + 5))
    echo -n "."
done

echo ""

# Create credentials (placeholders - user needs to update)
echo ""
print_info "Setting up Jenkins credentials..."
echo ""
print_warning "Creating placeholder credentials. YOU MUST UPDATE THESE WITH REAL VALUES!"
echo ""

# Create credentials directory if it doesn't exist
mkdir -p "$JENKINS_HOME/credentials"

# Create credentials using Groovy script
cat > /tmp/create-credentials.groovy << 'GROOVY_SCRIPT'
import jenkins.model.Jenkins
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.CredentialsProvider
import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import com.cloudbees.plugins.credentials.CredentialsScope

def jenkins = Jenkins.instance
def domain = Domain.global()
def store = jenkins.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// Define credentials
def credentials = [
    [id: 'team-email', description: 'Team email for notifications', secret: 'team@example.com'],
    [id: 'mongo-root-username', description: 'MongoDB root username', secret: 'admin'],
    [id: 'mongo-root-password', description: 'MongoDB root password', secret: 'changeme'],
    [id: 'api-gateway-url', description: 'API Gateway URL (local)', secret: 'http://localhost:8080'],
    [id: 'sonarqube-token', description: 'SonarQube authentication token', secret: 'CHANGE_ME_SONARQUBE_TOKEN'],
    [id: 'github-token', description: 'GitHub personal access token', secret: 'CHANGE_ME_GITHUB_TOKEN'],
]

credentials.each { cred ->
    def credential = new StringCredentialsImpl(
        CredentialsScope.GLOBAL,
        cred.id,
        cred.description,
        hudson.util.Secret.fromString(cred.secret)
    )
    
    try {
        store.addCredentials(domain, credential)
        println "✅ Created credential: ${cred.id}"
    } catch (Exception e) {
        println "⚠️  Credential ${cred.id} may already exist"
    }
}

jenkins.save()
println "Credentials setup complete"
GROOVY_SCRIPT

jenkins_cli groovy = < /tmp/create-credentials.groovy

# Create pipeline job
echo ""
print_info "Creating SafeZone pipeline job..."

cat > /tmp/create-pipeline-job.xml << 'XML_CONFIG'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <description>SafeZone CI/CD Pipeline - Local Deployment</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.BooleanParameterDefinition>
          <name>SKIP_TESTS</name>
          <description>Skip test execution (not recommended)</description>
          <defaultValue>false</defaultValue>
        </hudson.model.BooleanParameterDefinition>
        <hudson.model.BooleanParameterDefinition>
          <name>FORCE_REBUILD</name>
          <description>Force clean rebuild (ignore cache)</description>
          <defaultValue>false</defaultValue>
        </hudson.model.BooleanParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps">
    <scm class="hudson.plugins.git.GitSCM" plugin="git">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/YOUR_USERNAME/SafeZone.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>.pipeline/Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
XML_CONFIG

jenkins_cli create-job SafeZone-Pipeline < /tmp/create-pipeline-job.xml || print_warning "Job may already exist"

print_success "Pipeline job created"

# Configure SonarQube server
echo ""
print_info "Configuring SonarQube server in Jenkins..."

cat > /tmp/configure-sonarqube.groovy << 'GROOVY_SCRIPT'
import jenkins.model.Jenkins
import hudson.plugins.sonar.SonarGlobalConfiguration
import hudson.plugins.sonar.SonarInstallation

def jenkins = Jenkins.instance
def sonarConfig = jenkins.getDescriptor(SonarGlobalConfiguration.class)

def sonarInstallation = new SonarInstallation(
    'SonarQube',  // Name
    'http://localhost:9000',  // Server URL
    'sonarqube-token',  // Credential ID
    null,  // Additional analysis properties
    null,  // Additional properties
    null,  // Triggers
    null   // Webhook secret ID
)

sonarConfig.setInstallations(sonarInstallation)
sonarConfig.save()

println "✅ SonarQube server configured"
GROOVY_SCRIPT

jenkins_cli groovy = < /tmp/configure-sonarqube.groovy

echo ""
echo "=========================================="
echo "✅ Jenkins Configuration Complete!"
echo "=========================================="
echo ""
print_success "Jenkins is ready for use"
echo ""
print_warning "IMPORTANT: Update these credentials with real values!"
echo ""
echo "  1. Go to: $JENKINS_URL/credentials/"
echo "  2. Update these credential IDs:"
echo "     - sonarqube-token (get from SonarQube)"
echo "     - github-token (create at GitHub)"
echo "     - mongo-root-username & mongo-root-password"
echo "     - team-email"
echo ""
print_info "Next steps:"
echo "  1. Update the pipeline job Git repository URL"
echo "  2. Configure GitHub webhook"
echo "  3. Generate SonarQube token: http://localhost:9000"
echo "  4. Test the pipeline with a test branch"
echo ""
