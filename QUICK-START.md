# AWS Deployment Quick Reference

## One-Liner Quick Start

```bash
# 1. Configure AWS
aws configure

# 2. Run automated setup (creates RDS, S3, SNS)
chmod +x setup-aws.sh
./setup-aws.sh

# 3. Add GitHub secrets from .github-secrets.txt to your repository

# 4. Deploy
git add .
git commit -m "AWS deployment configuration"
git push origin main

# GitHub Actions will automatically build and deploy!
```

## Essential Commands

### Local Development
```bash
# Test database connection
mysql -h localhost -u root library < online-library-management-/Online\ Library\ Management\ System/SQL\ file/library.sql

# Run PHP development server
php -S localhost:8080 -t online-library-management-/Online\ Library\ Management\ System/SQL\ file/library
```

### AWS EB CLI Commands
```bash
# Initialize EB
eb init

# Create environment
eb create library-app-env --instance-type t3.micro

# Deploy code
eb deploy

# View logs
eb logs -z

# Check health
eb health --refresh

# SSH into instance
eb ssh

# Scale up/down
eb scale 2

# List environments
eb list-environments

# Terminate environment
eb terminate
```

### AWS CLI Commands
```bash
# RDS Management
aws rds describe-db-instances --region us-east-1
aws rds create-db-snapshot --db-instance-identifier library-db --db-snapshot-identifier backup-$(date +%s)

# CloudWatch Logs
aws logs tail /aws/elasticbeanstalk/library-app --follow
aws logs describe-log-streams --log-group-name /aws/elasticbeanstalk/library-app

# SNS Notifications
aws sns publish --topic-arn arn:aws:sns:region:account:library --message "test"

# S3 Deployment Packages
aws s3 ls s3://your-bucket-name/
```

## GitHub Actions Workflow

### Automatic on Push
1. Push to `main` or `develop` branch
2. GitHub Actions runs tests
3. Builds deployment package
4. Uploads to S3
5. Deploys to Elastic Beanstalk
6. Sends SNS notification

### Manual Deployment
```bash
# Re-deploy without code changes
eb deploy --region us-east-1

# Rebuild and deploy
eb deploy --timeout 30
```

## Environment Variables

### For Local Development
Create `.env.local`:
```env
APP_ENV=development
RDS_DB_HOST=localhost
RDS_DB_USER=root
RDS_DB_PASSWORD=
RDS_DB_NAME=library
```

### For AWS EB
Set via EB CLI:
```bash
eb setenv \
  APP_ENV=production \
  RDS_DB_HOST=your-endpoint.rds.amazonaws.com \
  RDS_DB_USER=admin \
  RDS_DB_PASSWORD=your-password \
  RDS_DB_NAME=library
```

## Troubleshooting Quick Links

| Issue | Solution |
|-------|----------|
| DB Connection Failed | Run `troubleshoot.sh` or check RDS security group |
| Deployment Timeout | Check `eb logs -z` and EB health status |
| CloudWatch No Logs | Verify IAM role has logs:PutLogEvents permission |
| SNS Not Working | Test with `aws sns publish --topic-arn ...` |
| Permission Denied | Check IAM role in `.ebextensions/04-iam.config` |

## File Structure After Setup

```
/workspaces/library/
├── .ebextensions/          # Elastic Beanstalk configuration
│   ├── 01-php.config       # PHP settings
│   ├── 02-logging.config   # Logging configuration
│   ├── 03-cloudwatch.config# CloudWatch integration
│   ├── 04-iam.config       # IAM permissions
│   └── 05-rds.config       # RDS database config
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions CI/CD pipeline
├── .elasticbeanstalk/
│   └── config.xml          # EB configuration
├── config-rds.php          # RDS-aware PHP config
├── .env.example            # Environment variables template
├── DEPLOYMENT-GUIDE.md     # Detailed deployment instructions
├── setup-aws.sh            # Automated AWS setup
├── deploy.sh               # Quick deployment script
└── troubleshoot.sh         # Troubleshooting helper
```

## Important Security Notes

⚠️ **NEVER COMMIT:**
- `.env*` files with real credentials
- AWS access keys or secrets
- Database passwords in code

✅ **DO:**
- Use AWS Secrets Manager for production
- Use GitHub Secrets for CI/CD
- Rotate credentials regularly
- Enable MFA on AWS account
- Use VPC and security groups properly

## Cost Estimate (Monthly)

| Service | Cost | Notes |
|---------|------|-------|
| EC2 t3.micro | Free (750h) | Elastic Beanstalk |
| RDS db.t3.micro | Free (750h) | MySQL 8.0 |
| Data Transfer | ~$0.10 | Minimal |
| CloudWatch Logs | Free (5GB) | Basic monitoring |
| SNS | Free (1000 emails) | Notifications |
| **Total** | **~$0/month** | With free tier |

> Costs increase if you exceed free tier limits or use multiple instances

## Support & Documentation

- 📖 [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) - Comprehensive step-by-step guide
- 🐛 [Run troubleshoot.sh](./troubleshoot.sh) - Diagnose issues
- 📋 [AWS Documentation](https://docs.aws.amazon.com/)
- 💬 [GitHub Discussions](https://github.com/walunjsneha5-pixel/library/discussions)

## Next Steps

1. ✅ Run `./setup-aws.sh` to create AWS resources
2. ✅ Add GitHub secrets from `.github-secrets.txt`
3. ✅ Commit and push to trigger deployment
4. ✅ Monitor deployment via GitHub Actions
5. ✅ Access application via EB environment URL

---

**Questions?** Check [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) or run `./troubleshoot.sh`
