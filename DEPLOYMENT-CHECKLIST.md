# AWS Deployment Checklist

Use this checklist to ensure you complete each step of the deployment process successfully.

## Pre-Deployment Setup

- [ ] **AWS Account Created**
  - Sign up at https://aws.amazon.com/
  - Enable billing alerts

- [ ] **AWS CLI Installed**
  - Run: `aws --version`
  - Document: [AWS CLI Installation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

- [ ] **EB CLI Installed**
  - Run: `pip install awsebcli`
  - Run: `eb --version`

- [ ] **AWS Credentials Configured**
  - Run: `aws configure`
  - Create IAM user with appropriate permissions
  - Note account ID and region

- [ ] **GitHub Account Setup**
  - Repository created at walunjsneha5-pixel/library
  - SSH keys configured (optional but recommended)
  - Repository cloned locally

- [ ] **Local Database Ready**
  - MySQL running locally
  - Database schema imported
  - Application tested locally

## Initial AWS Setup

- [ ] **Run Automated Setup Script**
  ```bash
  chmod +x setup-aws.sh
  ./setup-aws.sh
  ```
  - S3 bucket created for deployments
  - SNS topic created for notifications
  - Email subscription verified
  - RDS database created (optional)
  - .env.local created with credentials

- [ ] **Verify AWS Resources Created**
  ```bash
  aws s3 ls              # List S3 buckets
  aws rds describe-db-instances --region us-east-1  # List RDS instances
  aws sns list-topics --region us-east-1  # List SNS topics
  ```

- [ ] **Save AWS Credentials Securely**
  - Review and save: `aws sts get-caller-identity`
  - Store credentials in secure location (password manager)
  - Never commit credentials to git

## GitHub Configuration

- [ ] **Add GitHub Secrets**
  - Go to: Settings → Secrets and variables → Actions
  - Add secrets from `.github-secrets.txt`:
    - [ ] `AWS_ACCESS_KEY_ID`
    - [ ] `AWS_SECRET_ACCESS_KEY`
    - [ ] `AWS_REGION`
    - [ ] `S3_BUCKET_NAME`
    - [ ] `SNS_TOPIC_ARN`
    - [ ] `RDS_DB_HOST`
    - [ ] `RDS_DB_USER`
    - [ ] `RDS_DB_PASSWORD`

- [ ] **Review GitHub Actions Workflow**
  - Check: `.github/workflows/deploy.yml`
  - Verify triggers (push to main/develop)
  - Review deploy steps

- [ ] **Configure Repository Settings**
  - Enable branch protection for main
  - Require status checks to pass
  - Dismiss stale reviews

## Database Setup

- [ ] **Create RDS Instance** (if not done via setup script)
  ```bash
  aws rds describe-db-instances --region us-east-1
  ```
  - Instance identifier: `library-db`
  - Engine: MySQL 8.0
  - Class: db.t3.micro
  - Username: admin
  - Storage: 20 GB
  - Publicly accessible: Yes (for now)

- [ ] **Initialize Database**
  ```bash
  mysql -h $RDS_ENDPOINT -u admin -p library < database.sql
  ```
  - Schema imported successfully
  - Test tables created
  - Sample data loaded

- [ ] **Store Database Credentials**
  ```bash
  aws secretsmanager create-secret --name library/db --secret-string '{...}'
  ```
  - Secret created in AWS Secrets Manager
  - Accessible by EC2 IAM role

- [ ] **Test Database Connection**
  ```bash
  ./troubleshoot.sh  # Run diagnostics
  ```
  - Connection test passes
  - Credentials verified
  - Network connectivity confirmed

## Application Configuration

- [ ] **Review .ebextensions Files**
  - [ ] `01-php.config` - PHP settings correct
  - [ ] `02-logging.config` - Logging configured
  - [ ] `03-cloudwatch.config` - CloudWatch enabled
  - [ ] `04-iam.config` - IAM permissions set
  - [ ] `05-rds.config` - RDS resources defined

- [ ] **Update config-rds.php**
  - Copy provided `config-rds.php` or update existing
  - Uses environment variables
  - Supports both local and RDS connections

- [ ] **Create .env Files**
  - [ ] `.env.local` - For local development
  - [ ] `.env.production.local` - For production (not in repo)
  - [ ] `.env.example` - Template in repo

- [ ] **Update Application Code**
  - Use `getenv('VAR_NAME')` for configuration
  - Remove hardcoded database credentials
  - Test locally before pushing

## Elastic Beanstalk Setup

- [ ] **Initialize EB**
  ```bash
  eb init -p "PHP 7.4 running on 64bit Amazon Linux 2" \
          --region us-east-1 \
          library-app
  ```
  - EB application created
  - `.elasticbeanstalk/config.yml` generated
  - Platform version correct

- [ ] **Create EB Environment**
  ```bash
  eb create library-app-env --instance-type t3.micro
  ```
  - Environment name: `library-app-env`
  - Instance type: t3.micro
  - Environment created successfully
  - Health check passing

- [ ] **Configure Environment Variables in EB**
  ```bash
  eb setenv RDS_DB_HOST=... RDS_DB_USER=... RDS_DB_PASSWORD=...
  ```
  - All required variables set
  - Application deployed with variables

## Testing & Validation

- [ ] **Test GitHub Actions Pipeline**
  ```bash
  git add .
  git commit -m "AWS deployment config"
  git push origin main
  ```
  - Workflow triggered automatically
  - All steps complete successfully
  - No errors in build log
  - Deployment succeeds
  - SNS notification received

- [ ] **Test Application Accessibility**
  - [ ] Open EB URL in browser
  - [ ] Application loads successfully
  - [ ] Database connection working
  - [ ] Admin login page accessible
  - [ ] User login page accessible

- [ ] **Test Database Connectivity**
  ```bash
  mysql -h $RDS_HOST -u admin -p -e "SELECT 1;"
  ```
  - Connection successful
  - Query returns result

- [ ] **Check CloudWatch Logs**
  ```bash
  aws logs tail /aws/elasticbeanstalk/library-app --follow
  ```
  - Logs appearing in CloudWatch
  - No error messages
  - Application logging working

- [ ] **Verify SNS Notifications**
  - [ ] Deployment notification received
  - [ ] Email verified
  - [ ] Topic subscriptions active

## Monitoring Setup

- [ ] **Create CloudWatch Alarms**
  - [ ] High CPU utilization
  - [ ] High memory usage
  - [ ] Database connection failures
  - [ ] Application errors

- [ ] **Setup CloudWatch Dashboard**
  - [ ] CPU utilization metric
  - [ ] Memory usage metric
  - [ ] Request count metric
  - [ ] Error rate metric
  - [ ] Database performance metrics

- [ ] **Configure Log Retention**
  - [ ] Set retention period (7-30 days)
  - [ ] Enable log streaming
  - [ ] Verify logs are being collected

## Security Hardening

- [ ] **AWS Account Security**
  - [ ] Enable MFA on root account
  - [ ] Create IAM users instead of using root
  - [ ] Enable CloudTrail logging
  - [ ] Review and restrict IAM permissions

- [ ] **Database Security**
  - [ ] Change default database password
  - [ ] Configure security group to restrict access
  - [ ] Enable database encryption
  - [ ] Enable automated backups
  - [ ] Test backup restoration

- [ ] **Application Security**
  - [ ] Enable HTTPS (SSL/TLS)
  - [ ] Update security headers
  - [ ] Enable CORS if needed
  - [ ] Review and update PHP security settings
  - [ ] Update all dependencies to latest versions

- [ ] **Secrets Management**
  - [ ] Store credentials in Secrets Manager
  - [ ] Rotate credentials regularly
  - [ ] Remove any hardcoded secrets
  - [ ] Enable secret rotation policies

## Documentation

- [ ] **Documentation Complete**
  - [ ] README.md updated with deployment info
  - [ ] QUICK-START.md provides quick reference
  - [ ] DEPLOYMENT-GUIDE.md has detailed steps
  - [ ] AWS-SETUP-SUMMARY.md explains configuration
  - [ ] Comments added to .ebextensions files

- [ ] **Archive Important Information**
  - [ ] Save AWS account ID
  - [ ] Save RDS endpoint
  - [ ] Save EB application name
  - [ ] Save SNS topic ARN
  - [ ] Save S3 bucket name

## Post-Deployment

- [ ] **Monitor Application**
  ```bash
  eb health --refresh    # Check health continuously
  eb logs -z             # View application logs
  ```
  - Application running smoothly
  - No errors in logs
  - Health status is green

- [ ] **Performance Testing**
  - Load test with reasonable traffic
  - Monitor metrics during test
  - Verify auto-scaling works
  - Check database performance

- [ ] **Data Validation**
  - Verify all data in local database
  - Verify all data in RDS database
  - Run consistency checks
  - Validate reports and calculations

- [ ] **Backup Verification**
  - [ ] RDS automated backups enabled
  - [ ] Test backup restoration
  - [ ] Document backup location
  - [ ] Create initial manual backup

- [ ] **Cost Review**
  - Check AWS billing dashboard
  - Review service usage
  - Set up billing alerts
  - Verify free tier eligibility

## Maintenance Plan

- [ ] **Establish Maintenance Schedule**
  - [ ] Daily: Check logs and health
  - [ ] Weekly: Review metrics and performance
  - [ ] Monthly: Run diagnostics and updates
  - [ ] Quarterly: Security audit

- [ ] **Create Runbook**
  - [ ] Common issues and solutions
  - [ ] Emergency procedures
  - [ ] Rollback procedures
  - [ ] Contact information

- [ ] **Schedule Regular Tasks**
  - [ ] Database maintenance
  - [ ] Log cleanup
  - [ ] Credential rotation
  - [ ] Security patches
  - [ ] Backup verification

## Troubleshooting Reference

| Issue | Solution | Check |
|-------|----------|-------|
| DB Connection Failed | Run `troubleshoot.sh` | RDS security group |
| Deployment Timeout | Check `eb logs -z` | EB health status |
| Permission Denied | Review IAM role | `.ebextensions/04-iam.config` |
| No CloudWatch Logs | Verify IAM permissions | CloudWatch log groups |
| SNS Not Sending | Check topic ARN | SNS subscription status |

## Sign-Off

- [ ] **All checklist items completed**
- [ ] **Application tested and verified**
- [ ] **Monitoring and alerts configured**
- [ ] **Documentation complete**
- [ ] **Team trained on deployment**
- [ ] **Backup and recovery tested**

---

**Deployment Date:** ________________

**Completed By:** ________________

**Approved By:** ________________

**Notes:**
```
_________________________________________________________________

_________________________________________________________________

_________________________________________________________________
```

---

**For Help:**
1. Check [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md)
2. Run `./troubleshoot.sh`
3. Review [QUICK-START.md](./QUICK-START.md)
4. Check CloudWatch logs: `aws logs tail /aws/elasticbeanstalk/...`
