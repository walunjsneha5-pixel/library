# AWS Elastic Beanstalk Deployment Guide

## Prerequisites

1. **AWS Account** - [Create one here](https://aws.amazon.com/)
2. **AWS CLI** - [Install and configure](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
3. **EB CLI** - `pip install awsebcli`
4. **GitHub Account** - Repository access
5. **Git** - Version control

## Setup Steps

### Step 1: Configure AWS Credentials

```bash
# Configure AWS CLI with your credentials
aws configure

# You'll be prompted for:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (e.g., us-east-1)
# - Default output format (json)
```

Generate AWS credentials:
1. Go to [AWS IAM Console](https://console.aws.amazon.com/iam/)
2. Click "Users" → "Create user"
3. Attach policies:
   - `AdministratorAccess` (for testing)
   - Or use more restrictive policies:
     - `AWSElasticBeanstalkFullAccess`
     - `AmazonRDSFullAccess`
     - `AmazonS3FullAccess`
     - `CloudWatchFullAccess`
     - `AmazonSNSFullAccess`
4. Create access keys and save them securely

### Step 2: Prepare Your Application

**Update your PHP configuration to use environment variables:**

Replace hardcoded database credentials in your application files with:

```php
// Use environment variables for RDS connection
$dbHost = getenv('RDS_DB_HOST') ?: 'localhost';
$dbUser = getenv('RDS_DB_USER') ?: 'root';
$dbPass = getenv('RDS_DB_PASSWORD') ?: '';
$dbName = getenv('RDS_DB_NAME') ?: 'library';
```

Or copy the provided `config-rds.php` to your includes folder.

**Create .gitignore for secrets:**

```bash
.env
.env.local
.env.production.local
vendor/
node_modules/
.DS_Store
```

### Step 3: Initialize Elastic Beanstalk

```bash
# Navigate to your repository root
cd /workspaces/library

# Initialize EB application
eb init -p "PHP 7.4 running on 64bit Amazon Linux 2" \
        --region us-east-1 \
        library-app

# This creates:
# - .elasticbeanstalk/config.yml
# - .gitignore
```

### Step 4: Create Database and Secrets

#### Option A: AWS Management Console

1. **Create RDS Instance:**
   - Go to [RDS Console](https://console.aws.amazon.com/rds/)
   - Click "Create Database"
   - Engine: MySQL 8.0
   - Instance class: db.t3.micro (free tier eligible)
   - DB instance identifier: `library-db`
   - Master username: `admin`
   - Master password: Generate strong password
   - Publicly accessible: Yes (for now)
   - Create

2. **Store credentials in AWS Secrets Manager:**
   ```bash
   aws secretsmanager create-secret \
       --name library/db \
       --secret-string '{
           "username": "admin",
           "password": "your-password",
           "host": "your-rds-endpoint.region.rds.amazonaws.com"
       }' \
       --region us-east-1
   ```

#### Option B: Using AWS CLI

```bash
# Create RDS instance
aws rds create-db-instance \
    --db-instance-identifier library-db \
    --db-instance-class db.t3.micro \
    --engine mysql \
    --engine-version 8.0 \
    --master-username admin \
    --master-user-password 'YourSecurePassword123!' \
    --allocated-storage 20 \
    --storage-type gp2 \
    --publicly-accessible \
    --region us-east-1

# Wait for RDS to be available (5-10 minutes)
aws rds wait db-instance-available \
    --db-instance-identifier library-db \
    --region us-east-1
```

### Step 5: Create S3 Bucket for Deployments

```bash
# Create S3 bucket
aws s3api create-bucket \
    --bucket library-deployment-$(date +%s) \
    --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket your-bucket-name \
    --versioning-configuration Status=Enabled
```

### Step 6: Create SNS Topic for Notifications

```bash
# Create SNS topic
aws sns create-topic \
    --name library-deployment-alerts \
    --region us-east-1

# Subscribe to notifications (email)
aws sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:library-deployment-alerts \
    --protocol email \
    --notification-endpoint your-email@example.com
```

### Step 7: Setup GitHub Secrets

Go to your GitHub repository:
1. Settings → Secrets and variables → Actions
2. Create these secrets:

| Secret Name | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | Your IAM Access Key |
| `AWS_SECRET_ACCESS_KEY` | Your IAM Secret Key |
| `AWS_REGION` | us-east-1 |
| `S3_BUCKET_NAME` | Your S3 bucket name |
| `SNS_TOPIC_ARN` | Your SNS topic ARN |
| `RDS_DB_HOST` | Your RDS endpoint |
| `RDS_DB_USER` | admin |
| `RDS_DB_PASSWORD` | Your database password |

### Step 8: Deploy the Application

#### Method 1: Using EB CLI

```bash
# Create Elastic Beanstalk environment
eb create library-app-env \
    --instance-type t3.micro \
    --envvars RDS_DB_HOST=your-rds-endpoint,RDS_DB_USER=admin,RDS_DB_PASSWORD=yourpassword,RDS_DB_NAME=library

# Deploy application
eb deploy

# Open application in browser
eb open
```

#### Method 2: AWS Management Console

1. Go to [Elastic Beanstalk Console](https://console.aws.amazon.com/elasticbeanstalk/)
2. Click "Create application"
3. App name: `library-app`
4. Platform: `PHP 7.4 running on 64bit Amazon Linux 2`
5. Upload code (zip file)
6. Create environment

#### Method 3: GitHub Actions (Automated)

Push to main branch - GitHub Actions will automatically:
1. Run tests
2. Build deployment package
3. Deploy to EB
4. Send SNS notification

```bash
git add .
git commit -m "Deploy to AWS EB"
git push origin main
```

### Step 9: Initialize Database

```bash
# Get RDS endpoint
export RDS_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier library-db \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

# Import database schema
mysql -h $RDS_ENDPOINT \
      -u admin \
      -p \
      library < "online-library-management-/Online Library Management System/SQL file/library.sql"
```

### Step 10: Configure Environment Variables in EB

```bash
# Set environment variables
eb setenv \
    RDS_DB_HOST=your-rds-endpoint.region.rds.amazonaws.com \
    RDS_DB_USER=admin \
    RDS_DB_PASSWORD=yourpassword \
    RDS_DB_NAME=library \
    APP_ENV=production \
    APP_DEBUG=false \
    ENABLE_CLOUDWATCH=true

# Deploy changes
eb deploy
```

## Troubleshooting Common Issues

### Issue 1: Database Connection Error

```
Error: SQLSTATE[HY000]: General error: 2006 MySQL server has gone away
```

**Solution:**
1. Check RDS security group allows port 3306
2. Verify RDS endpoint in environment variables
3. Check credentials in Secrets Manager

```bash
# Test connection
mysql -h your-rds-endpoint.region.rds.amazonaws.com \
      -u admin \
      -p
```

### Issue 2: Deployment Timeout

```
Error: Environment update timed out
```

**Solution:**
1. Check EB logs: `eb logs`
2. Increase timeout in `.ebextensions/01-php.config`
3. Check application health: `eb health`

### Issue 3: Permission Denied Errors

```
Error: Unable to write to /var/www/html
```

**Solution:**
```bash
# Update IAM role permissions in .ebextensions/04-iam.config
# Re-deploy application
eb deploy
```

### Issue 4: CloudWatch Logs Not Appearing

**Solution:**
1. Check CloudWatch log group exists
2. Verify IAM role has CloudWatch permissions
3. Enable logs in `.ebextensions/03-cloudwatch.config`

**Check logs:**
```bash
# View EB logs
eb logs

# View CloudWatch logs
aws logs tail /aws/elasticbeanstalk/library-app --follow
```

### Issue 5: SNS Notifications Not Sending

**Solution:**
1. Verify SNS topic ARN in environment variables
2. Check SNS topic policy allows EC2 to publish
3. Verify email subscription is confirmed

## Monitoring and Maintenance

### View Application Logs

```bash
# Real-time logs
eb logs -z

# All available logs
eb logs --all

# CloudWatch logs
aws logs tail /aws/elasticbeanstalk/library-app --follow

# RDS logs
aws rds describe-db-log-files \
    --db-instance-identifier library-db \
    --query 'DescribeDBLogFiles[*].LogFileName'
```

### Monitor Application Health

```bash
# View environment health
eb health

# View recent events
eb events -f

# SSH into instance
eb ssh
```

### Scale Application

```bash
# View current configuration
eb config

# Increase instances (Auto Scaling)
eb scale 2  # 2 instances

# Monitor scaling
eb health --refresh
```

### Database Backups

```bash
# Automatic backups are enabled
# Manual backup
aws rds create-db-snapshot \
    --db-instance-identifier library-db \
    --db-snapshot-identifier library-backup-$(date +%s) \
    --region us-east-1

# List backups
aws rds describe-db-snapshots \
    --db-instance-identifier library-db
```

## Cost Optimization

1. **Use Free Tier:**
   - t3.micro EC2 instance (750 hours/month)
   - db.t3.micro RDS (750 hours/month)
   - 5GB CloudWatch Logs free

2. **Set Auto-scaling:**
   - Min instances: 1
   - Max instances: 2
   - Target CPU: 70%

3. **Enable CloudWatch Alarms:**
   - High CPU utilization
   - High memory usage
   - Database connection failures

## Security Best Practices

1. **Use AWS Secrets Manager** for database credentials
2. **Enable RDS encryption** at rest and in transit
3. **Use VPC** and security groups properly
4. **Enable MFA** for AWS account
5. **Rotate credentials** regularly
6. **Use HTTPS** (configure in EB)
7. **Keep software updated**

## Cleanup (Delete Resources)

```bash
# Delete Elastic Beanstalk environment
eb terminate

# Delete RDS instance
aws rds delete-db-instance \
    --db-instance-identifier library-db \
    --skip-final-snapshot

# Delete S3 bucket
aws s3 rm s3://your-bucket-name --recursive
aws s3api delete-bucket --bucket your-bucket-name

# Delete SNS topic
aws sns delete-topic --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:library-deployment-alerts
```

## Additional Resources

- [AWS Elastic Beanstalk Documentation](https://docs.aws.amazon.com/elasticbeanstalk/)
- [EB CLI Commands](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3.html)
- [RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [CloudWatch Monitoring](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## Support

For issues or questions:
1. Check [AWS Support Center](https://console.aws.amazon.com/support/)
2. Review CloudWatch logs
3. Check EB configuration: `eb config`
4. Contact AWS Support (Premium plans)
