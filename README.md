# Jenkins Production Docker Setup

A production-ready Jenkins deployment using Docker Compose with comprehensive security, monitoring, backup, and email configuration.

## 🚀 Features

### Core Components
- **Jenkins LTS** (2.440.3) with JDK 17
- **Docker-in-Docker** for containerized builds
- **Nginx Reverse Proxy** with SSL termination
- **Scalable Jenkins Agents**
- **Automated Backup System**

### Security & Authentication
- ✅ **Password Reset via Email** - Users can reset passwords securely
- ✅ **CSRF Protection** enabled
- ✅ **SSL/TLS Encryption** with Nginx
- ✅ **Rate Limiting** and security headers
- ✅ **Admin user auto-creation**
- ✅ **Restricted agent protocols**

### Email & Notifications
- ✅ **SMTP Configuration** (Gmail, Outlook, SES support)
- ✅ **Build Notifications** via email
- ✅ **Password Reset Emails**
- ✅ **Email Configuration Testing**
- ✅ **Rich email templates**

### Production Features
- ✅ **Health Checks** for all services
- ✅ **Persistent Data Storage**
- ✅ **Log Rotation** and management
- ✅ **Resource Limits** and monitoring
- ✅ **Network Isolation**
- ✅ **Automated Backups**

## 📋 Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 4GB RAM
- 20GB+ available disk space

## 🛠️ Quick Start

### 1. Clone and Setup

```bash
# Download all configuration files to your project directory
# Run the setup script
chmod +x setup.sh
./setup.sh
```

### 2. Configure Email (Important!)

Edit the `.env` file with your SMTP settings:

```bash
# Gmail Example
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-jenkins-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_USE_TLS=true
SMTP_USE_SSL=false
JENKINS_ADMIN_EMAIL=admin@yourcompany.com
JENKINS_URL=https://jenkins.yourcompany.com
```

### 3. Test Email Configuration

```bash
./test-email-config.sh
```

### 4. Update Domain Configuration

Edit `nginx/nginx.conf` and replace `jenkins.yourdomain.com` with your actual domain.

### 5. Start Jenkins

```bash
docker-compose up -d
```

### 6. Access Jenkins

- **Web Interface**: http://localhost:8080
- **Password Reset**: http://localhost:8080/forgotPassword
- **Default Admin**: Check `.env` file for generated credentials

## 📧 Email Configuration Guide

### Gmail Setup
1. Enable 2FA on your Google account
2. Generate an App Password: [Google App Passwords](https://myaccount.google.com/apppasswords)
3. Use the App Password (not your regular password) in `SMTP_PASSWORD`

### Outlook/Office365 Setup
```bash
SMTP_HOST=smtp-mail.outlook.com
SMTP_PORT=587
SMTP_USE_TLS=true
```

### Amazon SES Setup
```bash
SMTP_HOST=email-smtp.us-east-1.amazonaws.com
SMTP_PORT=587
SMTP_USER=your-ses-smtp-user
SMTP_PASSWORD=your-ses-smtp-password
```

### Testing Email
1. Run `./test-email-config.sh` to validate configuration
2. Check Jenkins logs: `docker-compose logs jenkins`
3. Test password reset functionality
4. Use Jenkins Script Console with the test email script

## 🗂️ File Structure

```
jenkins-production/
├── docker-compose.yml          # Main orchestration file
├── .env                        # Environment variables (SMTP, credentials)
├── setup.sh                   # Automated setup script
├── test-email-config.sh       # Email configuration tester
├── backup-jenkins.sh          # Backup automation script
├── monitor-jenkins.sh         # System monitoring script
├── nginx/
│   ├── nginx.conf             # Reverse proxy configuration
│   └── ssl/                   # SSL certificates directory
├── jenkins/
│   ├── plugins.txt            # Jenkins plugins list
│   ├── security.groovy        # Security configuration
│   ├── executors.groovy       # Executor configuration
│   ├── email-config.groovy    # Email setup script
│   └── test-email.groovy      # Email testing script
├── jenkins_home/              # Jenkins persistent data
├── logs/                      # Application logs
└── backups/                   # Automated backups
```

## 🔧 Configuration

### Environment Variables (.env)

| Variable | Description | Example |
|----------|-------------|---------|
| `JENKINS_ADMIN_USER` | Admin username | `admin` |
| `JENKINS_ADMIN_PASSWORD` | Admin password | `SecurePass123!` |
| `JENKINS_ADMIN_EMAIL` | Admin email address | `admin@company.com` |
| `SMTP_HOST` | SMTP server hostname | `smtp.gmail.com` |
| `SMTP_PORT` | SMTP server port | `587` |
| `SMTP_USER` | SMTP username | `jenkins@company.com` |
| `SMTP_PASSWORD` | SMTP password | `app-password` |
| `SMTP_USE_TLS` | Enable TLS encryption | `true` |
| `SMTP_USE_SSL` | Enable SSL encryption | `false` |
| `JENKINS_URL` | Public Jenkins URL | `https://jenkins.company.com` |

### SSL Configuration

For production, replace self-signed certificates:

```bash
# Place your certificates in nginx/ssl/
nginx/ssl/cert.pem    # SSL certificate
nginx/ssl/key.pem     # Private key
```

### Plugin Management

Edit `jenkins/plugins.txt` to customize installed plugins:

```
# Essential plugins
blueocean:latest
pipeline-stage-view:latest
email-ext:latest
git:latest
docker-workflow:latest
```

## 🎛️ Management Scripts

### Monitor Jenkins
```bash
./monitor-jenkins.sh
```
Shows container status, logs, resource usage, and disk space.

### Backup Jenkins
```bash
./backup-jenkins.sh
```
Creates compressed backup excluding workspace and logs. Automatically cleans old backups.

### Manual Backup
```bash
docker-compose run --rm backup
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f jenkins
docker-compose logs -f nginx
```

## 🔒 Security Best Practices

### 1. Change Default Credentials
```bash
# Update .env file
JENKINS_ADMIN_PASSWORD=YourSecurePassword123!
```

### 2. Enable HTTPS
- Use valid SSL certificates in production
- Configure proper DNS for your domain
- Update `JENKINS_URL` to use HTTPS

### 3. Network Security
- Use firewall rules to restrict access
- Consider VPN for admin access
- Monitor authentication attempts

### 4. Regular Updates
```bash
# Update Jenkins image
docker-compose pull
docker-compose up -d
```

## 🚨 Troubleshooting

### Email Issues

**Problem**: Password reset emails not sending
**Solution**:
1. Run `./test-email-config.sh` to validate configuration
2. Check SMTP credentials and server settings
3. Verify firewall/network connectivity to SMTP server
4. Check Jenkins logs: `docker-compose logs jenkins`

**Problem**: Gmail authentication fails
**Solution**:
1. Enable 2FA on Google account
2. Generate App Password (not regular password)
3. Use App Password in `SMTP_PASSWORD`

### Jenkins Issues

**Problem**: Jenkins won't start
**Solution**:
1. Check disk space: `df -h`
2. Verify permissions: `ls -la jenkins_home/`
3. Check logs: `docker-compose logs jenkins`

**Problem**: Build agents can't connect
**Solution**:
1. Verify agent secret in `.env`
2. Check network connectivity
3. Ensure port 50000 is accessible

### SSL Issues

**Problem**: SSL certificate errors
**Solution**:
1. Verify certificate files exist in `nginx/ssl/`
2. Check certificate validity: `openssl x509 -in nginx/ssl/cert.pem -text -noout`
3. Ensure proper permissions on certificate files

## 📊 Monitoring

### Health Checks
All services include health checks:
- Jenkins: HTTP endpoint check
- Nginx: Health endpoint
- Docker: Container status

### Resource Monitoring
```bash
# Real-time stats
docker stats

# Service-specific monitoring
./monitor-jenkins.sh
```

### Log Analysis
```bash
# Follow all logs
docker-compose logs -f

# Filter by service
docker-compose logs -f jenkins | grep ERROR

# Log locations
ls -la logs/
```

## 🔄 Backup & Recovery

### Automated Backups
- Runs daily via cron (set up separately)
- Excludes workspace and temporary files
- Retains last 7 days by default
- Stored in `./backups/` directory

### Manual Backup
```bash
./backup-jenkins.sh
```

### Restore from Backup
```bash
# Stop Jenkins
docker-compose stop jenkins

# Extract backup
tar -xzf backups/jenkins-backup-YYYYMMDD-HHMMSS.tar.gz -C jenkins_home/

# Fix permissions
sudo chown -R 1000:1000 jenkins_home/

# Restart Jenkins
docker-compose start jenkins
```

## 🏗️ Scaling

### Add More Agents
```yaml
# In docker-compose.yml, duplicate the jenkins-agent service
jenkins-agent-2:
  image: jenkins/inbound-agent:4.13.3-1-jdk17
  environment:
    - JENKINS_AGENT_NAME=docker-agent-2
    # ... other config
```

### External Database (Optional)
For larger deployments, consider external PostgreSQL:
```bash
# Add to .env
JENKINS_DB_HOST=postgres.example.com
JENKINS_DB_PORT=5432
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/improvement`
3. Test changes thoroughly
4. Submit pull request with detailed description

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

### Common Issues
- Check the troubleshooting section above
- Review logs: `docker-compose logs`
- Verify environment configuration

### Getting Help
- Jenkins Documentation: [jenkins.io/doc](https://jenkins.io/doc/)
- Docker Compose: [docs.docker.com/compose](https://docs.docker.com/compose/)
- Community Support: [Jenkins Community](https://www.jenkins.io/chat/)

---

## 📝 Quick Reference

### Essential Commands
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f jenkins

# Backup Jenkins
./backup-jenkins.sh

# Monitor system
./monitor-jenkins.sh

# Test email
./test-email-config.sh

# Update services
docker-compose pull && docker-compose up -d
```

### Important URLs
- **Jenkins Web UI**: http://localhost:8080
- **Password Reset**: http://localhost:8080/forgotPassword
- **Jenkins CLI**: http://localhost:8080/cli
- **System Information**: http://localhost:8080/systemInfo

### Default Credentials
Check the `.env` file for generated admin credentials.

---

**🎉 Your production Jenkins setup is ready!** 

Start with `docker-compose up -d` and access Jenkins at http://localhost:8080
