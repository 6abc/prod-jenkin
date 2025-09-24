#!/bin/bash

# Jenkins Email Configuration Test Script
# This script helps test and troubleshoot email configuration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Jenkins Email Configuration Tester${NC}"
echo "======================================="

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please create .env file with email configuration"
    exit 1
fi

# Source environment variables
source .env

echo -e "\n${YELLOW}Current Email Configuration:${NC}"
echo "SMTP Host: ${SMTP_HOST}"
echo "SMTP Port: ${SMTP_PORT}"
echo "SMTP User: ${SMTP_USER}"
echo "SMTP Use TLS: ${SMTP_USE_TLS}"
echo "SMTP Use SSL: ${SMTP_USE_SSL}"
echo "Admin Email: ${JENKINS_ADMIN_EMAIL}"
echo "Jenkins URL: ${JENKINS_URL}"

# Function to test SMTP connectivity
test_smtp_connection() {
    echo -e "\n${YELLOW}Testing SMTP Connection...${NC}"
    
    if [ "${SMTP_USE_SSL}" = "true" ]; then
        PROTOCOL="smtps"
    else
        PROTOCOL="smtp"
    fi
    
    timeout 10 bash -c "cat < /dev/null > /dev/tcp/${SMTP_HOST}/${SMTP_PORT}" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ SMTP server is reachable${NC}"
        return 0
    else
        echo -e "${RED}✗ Cannot connect to SMTP server${NC}"
        return 1
    fi
}

# Function to validate email format
validate_email() {
    local email=$1
    if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to create email test Groovy script
create_email_test_script() {
    cat > jenkins/test-email.groovy << 'EOF'
#!groovy
import jenkins.model.*
import hudson.tasks.Mailer
import javax.mail.*
import javax.mail.internet.*

def instance = Jenkins.getInstance()
def env = System.getenv()

def adminEmail = env['JENKINS_ADMIN_EMAIL']
def smtpHost = env['SMTP_HOST']
def smtpPort = env['SMTP_PORT']
def smtpUser = env['SMTP_USER']
def smtpPassword = env['SMTP_PASSWORD']

println "Sending test email to: ${adminEmail}"

try {
    // Create email properties
    Properties props = new Properties()
    props.put("mail.smtp.host", smtpHost)
    props.put("mail.smtp.port", smtpPort)
    props.put("mail.smtp.auth", "true")
    props.put("mail.smtp.starttls.enable", env['SMTP_USE_TLS'] ?: 'false')
    props.put("mail.smtp.ssl.enable", env['SMTP_USE_SSL'] ?: 'false')
    
    // Create session
    Session session = Session.getInstance(props, new Authenticator() {
        protected PasswordAuthentication getPasswordAuthentication() {
            return new PasswordAuthentication(smtpUser, smtpPassword)
        }
    })
    
    // Create message
    MimeMessage message = new MimeMessage(session)
    message.setFrom(new InternetAddress(smtpUser, "Jenkins System"))
    message.addRecipient(Message.RecipientType.TO, new InternetAddress(adminEmail))
    message.setSubject("Jenkins Email Test - " + new Date())
    message.setText("""This is a test email from Jenkins.

If you receive this email, your Jenkins email configuration is working correctly.

You can now:
✓ Reset passwords via email
✓ Receive build notifications
✓ Get system alerts

Jenkins URL: ${env['JENKINS_URL']}
Test sent at: ${new Date()}

This is an automated message.
""")
    
    // Send email
    Transport.send(message)
    println "✓ Test email sent successfully!"
    
} catch (Exception e) {
    println "✗ Failed to send test email: ${e.getMessage()}"
    e.printStackTrace()
}
EOF
}

# Main validation
echo -e "\n${YELLOW}Validating Configuration...${NC}"

# Check required variables
ERRORS=0

if [ -z "$SMTP_HOST" ]; then
    echo -e "${RED}✗ SMTP_HOST is not set${NC}"
    ERRORS=$((ERRORS + 1))
fi

if [ -z "$SMTP_PORT" ]; then
    echo -e "${RED}✗ SMTP_PORT is not set${NC}"
    ERRORS=$((ERRORS + 1))
fi

if [ -z "$JENKINS_ADMIN_EMAIL" ]; then
    echo -e "${RED}✗ JENKINS_ADMIN_EMAIL is not set${NC}"
    ERRORS=$((ERRORS + 1))
else
    if validate_email "$JENKINS_ADMIN_EMAIL"; then
        echo -e "${GREEN}✓ Admin email format is valid${NC}"
    else
        echo -e "${RED}✗ Admin email format is invalid${NC}"
        ERRORS=$((ERRORS + 1))
    fi
fi

if [ -z "$JENKINS_URL" ]; then
    echo -e "${YELLOW}⚠ JENKINS_URL is not set (recommended for password reset links)${NC}"
fi

# Test SMTP connection
test_smtp_connection

# Create test script
echo -e "\n${YELLOW}Creating email test script...${NC}"
create_email_test_script
echo -e "${GREEN}✓ Test script created at jenkins/test-email.groovy${NC}"

# Summary
echo -e "\n${BLUE}Summary:${NC}"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Email configuration appears to be valid${NC}"
    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo "1. Start Jenkins: docker-compose up -d"
    echo "2. Check logs: docker-compose logs jenkins"
    echo "3. Test password reset: Go to http://localhost:8080/forgotPassword"
    echo "4. Send test email: Copy jenkins/test-email.groovy to Jenkins script console"
else
    echo -e "${RED}✗ Found $ERRORS configuration errors${NC}"
    echo "Please fix the errors above before starting Jenkins"
fi

# Common SMTP configurations
echo -e "\n${BLUE}Common SMTP Configurations:${NC}"
echo "Gmail:"
echo "  SMTP_HOST=smtp.gmail.com"
echo "  SMTP_PORT=587"
echo "  SMTP_USE_TLS=true"
echo "  SMTP_USE_SSL=false"
echo "  (Use App Password, not regular password)"
echo ""
echo "Outlook/Office365:"
echo "  SMTP_HOST=smtp-mail.outlook.com"
echo "  SMTP_PORT=587"
echo "  SMTP_USE_TLS=true"
echo "  SMTP_USE_SSL=false"
echo ""
echo "Amazon SES:"
echo "  SMTP_HOST=email-smtp.[region].amazonaws.com"
echo "  SMTP_PORT=587"
echo "  SMTP_USE_TLS=true"
echo "  SMTP_USE_SSL=false"

echo -e "\n${GREEN}Email configuration test completed!${NC}"
