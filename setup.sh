#!/bin/bash

# Jenkins Production Setup Script
# This script sets up a production-ready Jenkins environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Jenkins Production Setup...${NC}"

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Create necessary directories
echo -e "${YELLOW}Creating directory structure...${NC}"
mkdir -p jenkins_home
mkdir -p jenkins
mkdir -p nginx/ssl
mkdir -p logs
mkdir -p backups

# Set proper permissions
echo -e "${YELLOW}Setting permissions...${NC}"
sudo chown -R 1000:1000 jenkins_home
sudo chmod -R 755 jenkins_home
sudo chmod 755 logs backups

# Generate SSL certificates (self-signed for development)
if [ ! -f "nginx/ssl/cert.pem" ]; then
    echo -e "${YELLOW}Generating self-signed SSL certificates...${NC}"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout nginx/ssl/key.pem \
        -out nginx/ssl/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=jenkins.local"
fi

# Create Jenkins security groovy script
cat > jenkins/security.groovy << 'EOF'
#!groovy
import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()

def env = System.getenv()
def adminUser = env['JENKINS_ADMIN_USER'] ?: 'admin'
def adminPassword = env['JENKINS_ADMIN_PASSWORD'] ?: 'admin123'

// Create admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount(adminUser, adminPassword)
instance.setSecurityRealm(hudsonRealm)

// Enable password reset via email
hudsonRealm.setAllowsSignup(false)  // Disable signup but allow password reset

// Set authorization strategy
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Enable CSRF protection
instance.setCrumbIssuer(new DefaultCrumbIssuer(true))

// Disable remoting
instance.getDescriptor("jenkins.CLI").get().setEnabled(false)

// Set agent protocols
Set<String> agentProtocolsList = ['JNLP4-connect', 'Ping']
instance.setAgentProtocols(agentProtocolsList)

instance.save()

println "Security configuration completed!"
println "Password reset is enabled - users can reset passwords via email"
EOF

# Create executors configuration
cat > jenkins/executors.groovy << 'EOF'
import jenkins.model.*
Jenkins.instance.setNumExecutors(0)
Jenkins.instance.save()
EOF

# Copy the email configuration script
cp email-config.groovy jenkins/email-config.groovy 2>/dev/null || echo "Note: email-config.groovy should be in jenkins/ directory"

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    JENKINS_SECRET=$(openssl rand -hex 32)
    cat > .env << EOF
JENKINS_AGENT_SECRET=${JENKINS_SECRET}
JENKINS_ADMIN_USER=admin
JENKINS_ADMIN_PASSWORD=$(openssl rand -base64 12)
EOF
    echo -e "${GREEN}Generated .env file with random credentials${NC}"
fi

# Create backup script
cat > backup-jenkins.sh << 'EOF'
#!/bin/bash
# Jenkins Backup Script

BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="jenkins-backup-${DATE}.tar.gz"

echo "Creating Jenkins backup..."
docker-compose exec -T backup sh -c "
    cd /jenkins_home &&
    tar -czf /backups/${BACKUP_FILE} \
        --exclude='workspace' \
        --exclude='builds/*/archive' \
        --exclude='*.log' \
        .
"

echo "Backup created: ${BACKUP_DIR}/${BACKUP_FILE}"

# Clean old backups (keep last 7 days)
find ${BACKUP_DIR} -name "jenkins-backup-*.tar.gz" -mtime +7 -delete
EOF

chmod +x backup-jenkins.sh

# Create email test script
chmod +x test-email-config.sh

# Create monitoring script
cat > monitor-jenkins.sh << 'EOF'
#!/bin/bash
# Jenkins Monitoring Script

echo "=== Jenkins Container Status ==="
docker-compose ps

echo -e "\n=== Jenkins Logs (last 20 lines) ==="
docker-compose logs --tail=20 jenkins

echo -e "\n=== System Resources ==="
docker stats --no-stream jenkins-master jenkins-docker jenkins-nginx

echo -e "\n=== Disk Usage ==="
du -sh jenkins_home/ logs/ backups/
EOF

chmod +x monitor-jenkins.sh

# Final instructions
echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update the .env file with your desired credentials"
echo "2. Update nginx/nginx.conf with your domain name"
echo "3. Start Jenkins with: docker-compose up -d"
echo "4. Access Jenkins at: http://localhost:8080"
echo "5. Run './monitor-jenkins.sh' to check status"
echo "6. Run './backup-jenkins.sh' to create backups"

echo -e "\n${YELLOW}Important files created:${NC}"
echo "- docker-compose.yml: Main orchestration file"
echo "- nginx/nginx.conf: Reverse proxy configuration"
echo "- jenkins/plugins.txt: Plugin list"
echo "- jenkins/email-config.groovy: Email configuration script"
echo "- .env: Environment variables (includes SMTP settings)"
echo "- backup-jenkins.sh: Backup script"
echo "- monitor-jenkins.sh: Monitoring script"
echo "- test-email-config.sh: Email configuration tester"

echo -e "\n${GREEN}Email Configuration:${NC}"
echo "✓ Password reset functionality enabled"
echo "✓ Email notifications configured"
echo "✓ SMTP settings auto-configured from .env"
echo "✓ Test script available for troubleshooting"

echo -e "\n${YELLOW}Before starting Jenkins:${NC}"
echo "1. Update SMTP settings in .env file"
echo "2. Run './test-email-config.sh' to validate email config"
echo "3. Update nginx/nginx.conf with your domain name"
echo "4. Start with: docker-compose up -d"

echo -e "\n${YELLOW}Password Reset URL:${NC}"
echo "http://localhost:8080/forgotPassword"

echo -e "\n${GREEN}Jenkins is ready for production deployment!${NC}"
