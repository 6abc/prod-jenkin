# Jenkins Environment Variables
# Copy this to .env file and update with your values

# Jenkins Agent Secret (generate with: openssl rand -hex 32)
JENKINS_AGENT_SECRET=your_secret_key_here

# Jenkins Admin Credentials
JENKINS_ADMIN_USER=admin
JENKINS_ADMIN_PASSWORD=your_secure_password_here
JENKINS_ADMIN_EMAIL=admin@yourcompany.com

# SMTP Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-jenkins-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_USE_TLS=true
SMTP_USE_SSL=false
JENKINS_URL=https://jenkins.yourcompany.com

# Database Configuration (if using external DB)
JENKINS_DB_HOST=localhost
JENKINS_DB_PORT=5432
JENKINS_DB_NAME=jenkins
JENKINS_DB_USER=jenkins
JENKINS_DB_PASSWORD=your_db_password_here

# SSL Configuration
SSL_CERT_PATH=./nginx/ssl/cert.pem
SSL_KEY_PATH=./nginx/ssl/key.pem

# Backup Configuration
BACKUP_RETENTION_DAYS=30
BACKUP_S3_BUCKET=your-jenkins-backups
AWS_ACCESS_KEY_ID=your_aws_key
AWS_SECRET_ACCESS_KEY=your_aws_secret

# Logging
LOG_LEVEL=INFO
LOG_MAX_SIZE=10m
LOG_MAX_FILES=3

# Resource Limits
JENKINS_MEMORY_LIMIT=4g
AGENT_MEMORY_LIMIT=2g
AGENT_CPU_LIMIT=1.0

# Network Configuration
JENKINS_SUBNET=172.20.0.0/16
EXTERNAL_PORT=80
EXTERNAL_SSL_PORT=443

# Security
JENKINS_CSRF_PROTECTION=true
JENKINS_SLAVE_AGENT_PORT=50000