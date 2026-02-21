# AWS Elastic Beanstalk Configuration Summary

## What's Been Configured

### 1. **Elastic Beanstalk (.ebextensions/)**
- **01-php.config** - PHP runtime configuration, memory limits, error handling
- **02-logging.config** - Application and PHP error log rotation
- **03-cloudwatch.config** - CloudWatch integration and log streaming
- **04-iam.config** - IAM roles and permissions for EC2 instances
- **05-rds.config** - RDS database configuration and Secrets Manager integration

### 2. **GitHub Actions CI/CD (.github/workflows/)**
- **deploy.yml** - Automated build, test, and deployment pipeline
  - Runs on push to main/develop
  - Tests PHP syntax
  - Builds deployment package
  - Uploads to S3
  - Deploys to Elastic Beanstalk
  - Sends SNS notifications

### 3. **Database Configuration**
- **config-rds.php** - Environment-aware PHP database configuration
  - Supports local MySQL and AWS RDS
  - Uses environment variables
  - Includes error handling and SNS notifications
  - Compatible with existing application

### 4. **Deployment Scripts**
- **setup-aws.sh** - Automated initial AWS setup
  - Creates S3 bucket for deployments
  - Creates SNS topic for notifications
  - Creates RDS MySQL database
  - Configures Elastic Beanstalk
  - Generates GitHub secrets file

- **deploy.sh** - Quick deployment script
  - Creates EB environment
  - Deploys application
  - Provides application URL

- **troubleshoot.sh** - Diagnostic and troubleshooting tool
  - Checks all AWS services
  - Tests database connectivity
  - Verifies configurations
  - Provides solutions

### 5. **Documentation**
- **DEPLOYMENT-GUIDE.md** - Comprehensive deployment instructions
- **QUICK-START.md** - Quick reference guide
- **.env.example** - Environment variables template

## Architecture Overview

```
GitHub Repository
       ↓
   GitHub Actions
   (CI/CD Pipeline)
       ↓
   Test & Build
       ↓
    S3 Upload
       ↓
AWS Elastic Beanstalk
  Auto Scaling Group
   EC2 Instances
    Load Balancer
       ↓
    Application
       ↓
  RDS MySQL
  Database
       ↓
   CloudWatch
   Monitoring
       ↓
     SNS
 Notifications
```

## Deployment Flow

1. **Developer pushes code** to GitHub
2. **GitHub Actions** automatically:
   - Runs tests and checks
   - Builds deployment package
   - Uploads to S3
   - Deploys to Elastic Beanstalk
3. **Elastic Beanstalk** automatically:
   - Stops current application
   - Extracts new code
   - Runs .ebextensions configuration
   - Starts new application
4. **Load Balancer** routes traffic to new version
5. **CloudWatch** monitors application
6. **SNS** sends success/failure notification

## Security Features

✅ **Implemented:**
- Environment variables for sensitive data
- AWS Secrets Manager integration
- IAM roles with minimal permissions
- CloudWatch encryption
- RDS encryption at rest
- Database backups enabled
- Security group configuration
- HTTPS-ready (configure in EB)

## AWS Services Used

| Service | Purpose | Cost |
|---------|---------|------|
| **EC2 (t3.micro)** | Application server | Free tier |
| **RDS (db.t3.micro)** | MySQL database | Free tier |
| **S3** | Deployment packages | Free tier (5GB) |
| **Elastic Beanstalk** | Hosting platform | Free tier |
| **CloudWatch** | Monitoring & logs | Free tier (5GB) |
| **SNS** | Email notifications | Free tier (1K emails) |
| **Secrets Manager** | Store credentials | $0.40/secret/month |
| **IAM** | Access control | Free |

**Total monthly cost with free tier: ~$0.40 (for Secrets Manager)**

## Environment Variables

### Required for Production
```
RDS_DB_HOST          - RDS endpoint
RDS_DB_USER          - Database username
RDS_DB_PASSWORD      - Database password
RDS_DB_NAME          - Database name
APP_ENV              - Environment (production/staging)
APP_DEBUG            - Debug mode (true/false)
```

### Optional
```
ENABLE_CLOUDWATCH    - Enable CloudWatch integration
SNS_TOPIC_ARN        - SNS topic for notifications
LOG_LEVEL            - Log level (debug/info/warning/error)
```

## Monitoring & Maintenance

### CloudWatch Dashboards
Create custom dashboards to monitor:
- ApplicationRequests
- DatabaseConnections
- CPUUtilization
- MemoryUtilization

### Health Checks
Elastic Beanstalk performs health checks on:
- HTTP status codes
- Response time
- System metrics

### Backups
- **RDS**: Daily automatic backups (7-day retention)
- **Application**: Version history in EB
- **Database Snapshots**: Manual backups available

## Scaling Configuration

### Current Settings
- **Min instances**: 1
- **Max instances**: 2 (configurable)
- **Load balancer**: Application Load Balancer (ALB)
- **Instance type**: t3.micro (configurable)

### To Scale Up/Down
```bash
eb scale 3          # Set to 3 instances
eb setenv AUTO_SCALING_MIN_SIZE=2 AUTO_SCALING_MAX_SIZE=5
```

## Troubleshooting

### Common Issues

**1. Database Connection Error**
```bash
./troubleshoot.sh  # Run diagnostic
# Check RDS security group allows 3306
# Verify environment variables
```

**2. Deployment Timeout**
```bash
eb logs -z         # View logs
eb health --refresh # Check health
```

**3. Permission Denied**
```bash
# Update IAM role in .ebextensions/04-iam.config
eb deploy          # Re-deploy
```

### Debug Commands
```bash
eb status              # Check environment status
eb health              # Monitor health
eb logs -z             # View application logs
eb events -f           # Monitor recent events
eb ssh                 # SSH into instance
aws logs tail /aws/elasticbeanstalk/...  # Stream logs
```

## Updating Application

### Method 1: Automatic (GitHub Actions)
```bash
git add .
git commit -m "Update application"
git push origin main
# GitHub Actions will automatically deploy
```

### Method 2: Manual
```bash
eb deploy --region us-east-1
```

### Method 3: AWS Console
1. Go to Elastic Beanstalk
2. Upload new version
3. Select and deploy

## Rollback to Previous Version

```bash
# List application versions
aws elasticbeanstalk describe-application-versions

# Deploy previous version
eb deploy --version=previous-version-label
```

## Database Management

### Connect to RDS
```bash
mysql -h $RDS_DB_HOST -u admin -p library
```

### Backup Database
```bash
aws rds create-db-snapshot \
  --db-instance-identifier library-db \
  --db-snapshot-identifier backup-$(date +%s)
```

### Restore from Backup
```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier library-db-restored \
  --db-snapshot-identifier backup-id
```

## Cost Optimization

1. **Use free tier** (requires AWS account < 12 months)
2. **Auto-scaling** to manage costs
3. **Scheduled scaling** for predictable traffic
4. **CloudWatch alarms** for monitoring
5. **Reserved instances** for predictable usage
6. **RDS read replicas** for read-heavy workloads

## Next Actions

1. ✅ Run `./setup-aws.sh` to initialize AWS resources
2. ✅ Add GitHub secrets (from .github-secrets.txt)
3. ✅ Update database configuration
4. ✅ Test locally first
5. ✅ Commit and push to GitHub
6. ✅ Monitor GitHub Actions deployment
7. ✅ Access application via EB URL
8. ✅ Set up custom domain (Route 53)
9. ✅ Enable HTTPS (ACM Certificate)
10. ✅ Configure backup strategy

## Support

📖 **Documentation**
- [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) - Step-by-step instructions
- [QUICK-START.md](./QUICK-START.md) - Quick reference
- [AWS Documentation](https://docs.aws.amazon.com/elasticbeanstalk/)

🐛 **Troubleshooting**
- Run: `./troubleshoot.sh`
- Check logs: `eb logs -z`
- Monitor health: `eb health --refresh`

💬 **Community**
- AWS Support
- GitHub Discussions
- Stack Overflow

---

**Ready to deploy?** Start with: `./setup-aws.sh`
