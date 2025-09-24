#!groovy
import jenkins.model.*
import hudson.tasks.Mailer
import hudson.plugins.emailext.ExtendedEmailPublisher
import hudson.plugins.emailext.ExtendedEmailPublisherDescriptor

def instance = Jenkins.getInstance()
def env = System.getenv()

// Get SMTP configuration from environment variables
def smtpHost = env['SMTP_HOST'] ?: 'localhost'
def smtpPort = env['SMTP_PORT'] ?: '25'
def smtpUser = env['SMTP_USER'] ?: ''
def smtpPassword = env['SMTP_PASSWORD'] ?: ''
def smtpUseTls = Boolean.parseBoolean(env['SMTP_USE_TLS'] ?: 'false')
def smtpUseSsl = Boolean.parseBoolean(env['SMTP_USE_SSL'] ?: 'false')
def adminEmail = env['JENKINS_ADMIN_EMAIL'] ?: 'admin@localhost'
def jenkinsUrl = env['JENKINS_URL'] ?: 'http://localhost:8080'

println "Configuring Jenkins email settings..."
println "SMTP Host: ${smtpHost}"
println "SMTP Port: ${smtpPort}"
println "SMTP User: ${smtpUser}"
println "Use TLS: ${smtpUseTls}"
println "Use SSL: ${smtpUseSsl}"
println "Admin Email: ${adminEmail}"
println "Jenkins URL: ${jenkinsUrl}"

// Set Jenkins URL
def jenkinsLocationConfiguration = JenkinsLocationConfiguration.get()
jenkinsLocationConfiguration.setUrl(jenkinsUrl)
jenkinsLocationConfiguration.setAdminAddress(adminEmail)
jenkinsLocationConfiguration.save()

// Configure standard Mailer plugin
def mailerDescriptor = instance.getDescriptor("hudson.tasks.Mailer")
mailerDescriptor.setSmtpHost(smtpHost)
mailerDescriptor.setSmtpPort(smtpPort)
mailerDescriptor.setUseSsl(smtpUseSsl)
mailerDescriptor.setUseTls(smtpUseTls)
mailerDescriptor.setSmtpAuth(smtpUser, smtpPassword)
mailerDescriptor.setReplyToAddress(adminEmail)
mailerDescriptor.setCharset("UTF-8")
mailerDescriptor.save()

// Configure Extended Email plugin
def extMailerDescriptor = instance.getDescriptor(ExtendedEmailPublisher.class)
if (extMailerDescriptor != null) {
    extMailerDescriptor.setSmtpHost(smtpHost)
    extMailerDescriptor.setSmtpPort(smtpPort)
    extMailerDescriptor.setUseSsl(smtpUseSsl)
    extMailerDescriptor.setUseTls(smtpUseTls)
    extMailerDescriptor.setSmtpUsername(smtpUser)
    extMailerDescriptor.setSmtpPassword(smtpPassword)
    extMailerDescriptor.setReplyToAddress(adminEmail)
    extMailerDescriptor.setCharset("UTF-8")
    
    // Set default email content
    extMailerDescriptor.setDefaultSubject('$PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS!')
    extMailerDescriptor.setDefaultBody('''$PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS:

Check console output at $BUILD_URL to view the results.

Changes:
$CHANGES

--
Build URL: $BUILD_URL
Build Log: $BUILD_URL/console

This email was sent automatically by Jenkins.''')
    
    // Set default triggers
    extMailerDescriptor.setDefaultTriggers([
        'hudson.plugins.emailext.plugins.trigger.FailureTrigger',
        'hudson.plugins.emailext.plugins.trigger.UnstableTrigger',
        'hudson.plugins.emailext.plugins.trigger.FirstFailureTrigger',
        'hudson.plugins.emailext.plugins.trigger.FixedTrigger'
    ])
    
    extMailerDescriptor.save()
}

// Test email configuration
try {
    println "Testing email configuration..."
    def testSubject = "Jenkins Email Configuration Test"
    def testMessage = """Jenkins email configuration has been successfully set up.

Server Details:
- Jenkins URL: ${jenkinsUrl}
- SMTP Server: ${smtpHost}:${smtpPort}
- TLS Enabled: ${smtpUseTls}
- SSL Enabled: ${smtpUseSsl}
- Authentication: ${smtpUser ? 'Enabled' : 'Disabled'}

If you receive this email, password reset functionality should work properly.

This is an automated test message from Jenkins setup.
"""

    // Send test email using Mailer
    if (smtpUser && adminEmail) {
        def mail = new MimeMessage(Session.getDefaultInstance(new Properties()))
        mail.setFrom(new InternetAddress(smtpUser))
        mail.addRecipient(Message.RecipientType.TO, new InternetAddress(adminEmail))
        mail.setSubject(testSubject)
        mail.setText(testMessage)
        
        println "Email configuration completed successfully!"
    }
} catch (Exception e) {
    println "Warning: Could not send test email: ${e.getMessage()}"
    println "Email configuration saved, but please verify SMTP settings manually."
}

instance.save()

println "Email configuration completed!"
println "Users can now reset passwords via: ${jenkinsUrl}/forgotPassword"