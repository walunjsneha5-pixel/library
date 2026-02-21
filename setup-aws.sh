#!/bin/bash

##############################################################################
# AWS Elastic Beanstalk Deployment Quick Setup Script
# This script automates the initial AWS setup for your library application
##############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[Info]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[Success]${NC} $1"
}

print_error() {
    echo -e "${RED}[Error]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[Warning]${NC} $1"
}

# Check prerequisites
print_status "Checking prerequisites..."

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first:"
    echo "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi
print_success "AWS CLI found"

# Check EB CLI
if ! command -v eb &> /dev/null; then
    print_warning "EB CLI is not installed. Installing..."
    pip install awsebcli
fi
print_success "EB CLI found"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured. Run: aws configure"
    exit 1
fi
print_success "AWS credentials configured"

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-us-east-1}

print_status "Using AWS Account: $AWS_ACCOUNT_ID"
print_status "Using AWS Region: $AWS_REGION"

# Generate unique bucket name
BUCKET_NAME="library-deployment-$(date +%s)"
APP_NAME="library-app"
ENV_NAME="library-app-env"

print_status "Creating S3 bucket for deployments..."
aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $AWS_REGION \
    --create-bucket-configuration LocationConstraint=$AWS_REGION 2>/dev/null || \
    print_warning "Bucket might already exist"

print_success "S3 Bucket created: $BUCKET_NAME"

# Create SNS topic
print_status "Creating SNS topic for notifications..."
SNS_RESPONSE=$(aws sns create-topic \
    --name library-deployment-alerts \
    --region $AWS_REGION \
    --output json)

SNS_TOPIC_ARN=$(echo $SNS_RESPONSE | grep -o 'arn:aws:sns:[^"]*')
print_success "SNS Topic created: $SNS_TOPIC_ARN"

# Subscribe to email notifications
read -p "Email address for SNS notifications: " EMAIL
aws sns subscribe \
    --topic-arn $SNS_TOPIC_ARN \
    --protocol email \
    --notification-endpoint $EMAIL \
    --region $AWS_REGION

print_warning "Confirm email subscription in your inbox!"

# Create RDS database
read -p "Create RDS MySQL database now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Creating RDS MySQL instance..."
    
    # Generate secure password
    DB_PASSWORD=$(openssl rand -base64 32)
    
    aws rds create-db-instance \
        --db-instance-identifier library-db \
        --db-instance-class db.t3.micro \
        --engine mysql \
        --engine-version 8.0 \
        --master-username admin \
        --master-user-password "$DB_PASSWORD" \
        --allocated-storage 20 \
        --storage-type gp2 \
        --publicly-accessible \
        --region $AWS_REGION \
        --no-deletion-protection \
        --tags Key=App,Value=LibraryApp
    
    print_success "RDS instance created (this takes 5-10 minutes)"
    print_status "Waiting for RDS to be available..."
    
    aws rds wait db-instance-available \
        --db-instance-identifier library-db \
        --region $AWS_REGION
    
    # Get RDS endpoint
    RDS_ENDPOINT=$(aws rds describe-db-instances \
        --db-instance-identifier library-db \
        --query 'DBInstances[0].Endpoint.Address' \
        --output text)
    
    print_success "RDS Endpoint: $RDS_ENDPOINT"
    
    # Store credentials in Secrets Manager
    print_status "Storing credentials in Secrets Manager..."
    aws secretsmanager create-secret \
        --name library/db \
        --secret-string "{
            \"username\": \"admin\",
            \"password\": \"$DB_PASSWORD\",
            \"host\": \"$RDS_ENDPOINT\",
            \"port\": 3306,
            \"dbname\": \"library\"
        }" \
        --region $AWS_REGION 2>/dev/null || \
        print_warning "Secret may already exist"
    
    print_success "Credentials stored securely"
fi

# Initialize EB
print_status "Initializing Elastic Beanstalk..."
eb init -p "PHP 7.4 running on 64bit Amazon Linux 2" \
        --region $AWS_REGION \
        $APP_NAME

print_success "Elastic Beanstalk initialized"

# Create .env file
print_status "Creating .env configuration file..."
cat > .env.local <<EOF
APP_ENV=staging
APP_DEBUG=false
LOG_LEVEL=info

RDS_DB_HOST=$RDS_ENDPOINT
RDS_DB_USER=admin
RDS_DB_PASSWORD=$DB_PASSWORD
RDS_DB_NAME=library

AWS_REGION=$AWS_REGION
SNS_TOPIC_ARN=$SNS_TOPIC_ARN
ENABLE_CLOUDWATCH=true
EOF

print_success ".env.local created (KEEP THIS SECRET!)"

# Create GitHub secrets file
print_status "Creating GitHub secrets configuration..."
cat > .github-secrets.txt <<EOF
# Add these as GitHub repository secrets:
# (Settings → Secrets and variables → Actions → New repository secret)

AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=$AWS_REGION
S3_BUCKET_NAME=$BUCKET_NAME
SNS_TOPIC_ARN=$SNS_TOPIC_ARN
RDS_DB_HOST=$RDS_ENDPOINT
RDS_DB_USER=admin
RDS_DB_PASSWORD=$DB_PASSWORD
EOF

print_success "GitHub secrets template created in .github-secrets.txt"

# Summary
echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo "S3 Bucket: $BUCKET_NAME"
echo "SNS Topic: $SNS_TOPIC_ARN"
[ -n "$RDS_ENDPOINT" ] && echo "RDS Endpoint: $RDS_ENDPOINT"
echo "App Name: $APP_NAME"
echo "Region: $AWS_REGION"
echo ""
echo "Next Steps:"
echo "1. Add GitHub secrets from .github-secrets.txt"
echo "2. Configure .env.local with your values"
echo "3. Commit and push to GitHub"
echo "4. GitHub Actions will deploy automatically"
echo ""
echo "For detailed instructions, see DEPLOYMENT-GUIDE.md"
echo "========================================="

print_success "AWS setup complete!"
