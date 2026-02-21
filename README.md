# Online Library Management System

A comprehensive PHP-based library management system designed for educational institutions. Supports user management, book catalog, issue/return tracking, and administrative dashboard.

## Features

- 👤 **User Management** - Student registration and login
- 📚 **Book Catalog** - Complete book management with categories and authors
- 📋 **Issue/Return System** - Track book borrowing and returns
- 👨‍💼 **Admin Dashboard** - Manage books, students, and issuances
- 📊 **Reports** - Availability and history tracking
- 🔐 **Secure Authentication** - Password protection for users

## Quick Start (Local Development)

### Prerequisites
- PHP 7.4+
- MySQL 8.0+
- Apache/Nginx web server

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/walunjsneha5-pixel/library.git
cd library
```

2. **Import database**
```bash
mysql -u root -p library < "online-library-management-/Online Library Management System/SQL file/library.sql"
```

3. **Update database configuration**
Edit `config-rds.php` with your database credentials

4. **Start PHP server**
```bash
php -S localhost:8080
```

## AWS Deployment

This project includes complete AWS EB deployment configuration with GitHub Actions CI/CD.

### ⚡ Quick Deploy (3 Steps)

```bash
# 1. Configure AWS
aws configure

# 2. Run automated setup
chmod +x setup-aws.sh && ./setup-aws.sh

# 3. Push to GitHub
git add . && git commit -m "AWS deployment" && git push origin main
```

GitHub Actions will automatically deploy!

### 📖 Documentation

| Document | Purpose |
|----------|---------|
| [QUICK-START.md](./QUICK-START.md) | Fast reference guide |
| [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) | Detailed step-by-step instructions |
| [AWS-SETUP-SUMMARY.md](./AWS-SETUP-SUMMARY.md) | Configuration overview |

## Architecture

```
GitHub → GitHub Actions → AWS EB → RDS MySQL
                           ↓
                       CloudWatch
                           ↓
                           SNS
```

**Services:**
- ☁️ AWS Elastic Beanstalk - Application hosting
- 🗄️ Amazon RDS - MySQL database  
- 📊 CloudWatch - Monitoring & logging
- 📧 SNS - Email notifications
- 📦 S3 - Deployment packages

## Essential Commands

```bash
# AWS Setup
./setup-aws.sh              # Automated AWS setup
./deploy.sh                 # Quick deployment
./troubleshoot.sh           # Diagnose issues

# EB CLI
eb init                     # Initialize Elastic Beanstalk
eb create                   # Create environment
eb deploy                   # Deploy application
eb logs -z                  # View application logs
eb health --refresh         # Check environment health
eb open                     # Open in browser
```

## Environment Variables

### Local Development
```env
APP_ENV=development
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=library
```

### AWS Production
```env
RDS_DB_HOST=your-endpoint.rds.amazonaws.com
RDS_DB_USER=admin
RDS_DB_PASSWORD=secure-password
RDS_DB_NAME=library
APP_ENV=production
ENABLE_CLOUDWATCH=true
SNS_TOPIC_ARN=arn:aws:sns:...
```

## CI/CD Pipeline

**GitHub Actions automatically:**
1. Runs tests and checks
2. Builds deployment package
3. Uploads to S3
4. Deploys to Elastic Beanstalk
5. Sends SNS notification

**Setup:** Add GitHub secrets from `.github-secrets.txt` to your repository

## Estimated Monthly Cost

**With AWS Free Tier (first 12 months):**
- EC2 t3.micro: Free (750 hours)
- RDS db.t3.micro: Free (750 hours)
- CloudWatch: Free (5 GB)
- SNS: Free (1,000 emails)
- S3: Free (5 GB)
- **Total:** ~$0.40/month (Secrets Manager)

## Troubleshooting

```bash
# Run diagnostic tool
./troubleshoot.sh

# View application logs
eb logs -z

# Check environment health
eb health --refresh

# SSH into instance
eb ssh
```

See [DEPLOYMENT-GUIDE.md#troubleshooting-common-issues](./DEPLOYMENT-GUIDE.md#troubleshooting-common-issues) for solutions to common problems.

## Project Structure

```
library/
├── .ebextensions/           # Elastic Beanstalk config
├── .github/workflows/       # GitHub Actions CI/CD
├── .elasticbeanstalk/       # EB CLI config
├── online-library-management-/  # Application source
├── config-rds.php           # RDS-aware config
├── setup-aws.sh             # AWS setup script
├── deploy.sh                # Deployment script
├── troubleshoot.sh          # Diagnostic tool
├── DEPLOYMENT-GUIDE.md      # Full documentation
├── QUICK-START.md           # Quick reference
└── AWS-SETUP-SUMMARY.md     # Setup overview
```

## Support & Documentation

📖 **Start Here:**
- [QUICK-START.md](./QUICK-START.md) - Quick reference
- [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) - Complete instructions
- [AWS-SETUP-SUMMARY.md](./AWS-SETUP-SUMMARY.md) - Configuration details

🐛 **Troubleshooting:**
- Run: `./troubleshoot.sh`
- Check logs: `eb logs -z`
- Review: [DEPLOYMENT-GUIDE.md#troubleshooting](./DEPLOYMENT-GUIDE.md#troubleshooting-common-issues)

📚 **Resources:**
- [AWS Elastic Beanstalk Docs](https://docs.aws.amazon.com/elasticbeanstalk/)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [PHP Documentation](https://www.php.net/docs.php)
- [MySQL Documentation](https://dev.mysql.com/doc/)

## Security Best Practices

✅ **Implemented:**
- Environment variables for sensitive data
- AWS Secrets Manager integration
- IAM role-based access control
- Database encryption at rest
- CloudWatch monitoring
- Automated backups

⚠️ **Do's:**
- Never commit `.env` files with real credentials
- Rotate database passwords regularly
- Enable MFA on AWS accounts
- Use VPC and security groups properly
- Keep dependencies updated

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Push to GitHub
6. Create a Pull Request

## License

This project is provided as-is for educational and development purposes.

## Authors

- **Original Application:** Multiple Contributors
- **AWS Deployment Configuration:** GitHub Copilot (2026)

## Acknowledgments

- AWS for excellent cloud infrastructure
- PHP community for frameworks and tools
- All contributors and testers

---

## Next Steps

1. ✅ **Start Deployment:** [QUICK-START.md](./QUICK-START.md)
2. ✅ **Detailed Guide:** [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md)
3. ✅ **Setup Summary:** [AWS-SETUP-SUMMARY.md](./AWS-SETUP-SUMMARY.md)
4. ✅ **Troubleshooting:** Run `./troubleshoot.sh`

---

**Questions?** Check the documentation or run the troubleshooting script.

**Ready to deploy?** Start with: `./setup-aws.sh`
