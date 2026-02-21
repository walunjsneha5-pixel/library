#!/bin/bash

##############################################################################
# Troubleshooting Script for AWS Elastic Beanstalk Deployment
# Diagnoses common issues and provides solutions
##############################################################################

set -e

REGION=${AWS_REGION:-us-east-1}
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_title() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_ok() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

echo "========================================="
echo "AWS EB Troubleshooting Diagnostic"
echo "========================================="
echo ""

# 1. Check AWS CLI
print_title "Checking AWS CLI Configuration"
if aws sts get-caller-identity &>/dev/null; then
    ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    print_ok "AWS CLI configured (Account: $ACCOUNT)"
else
    print_error "AWS CLI not configured. Run: aws configure"
fi
echo ""

# 2. Check EB Application
print_title "Checking Elastic Beanstalk Application"
APP=$(eb list-applications --region $REGION 2>/dev/null || echo "")
if [ -z "$APP" ]; then
    print_error "No EB applications found"
else
    print_ok "EB Applications found"
fi
echo ""

# 3. Check EB Environment Status
print_title "Checking Elastic Beanstalk Environment Health"
if ! eb status &>/dev/null; then
    print_warning "Could not retrieve EB status"
else
    print_ok "EB Environment is responsive"
fi
echo ""

# 4. Check RDS Database
print_title "Checking RDS Database"
RDS_INSTANCES=$(aws rds describe-db-instances \
    --region $REGION \
    --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]' \
    --output text 2>/dev/null || echo "")

if [ -z "$RDS_INSTANCES" ]; then
    print_warning "No RDS instances found"
else
    echo "$RDS_INSTANCES" | while read -r name status; do
        if [ "$status" = "available" ]; then
            print_ok "RDS Instance '$name' is available"
        else
            print_warning "RDS Instance '$name' status: $status"
        fi
    done
fi
echo ""

# 5. Test Database Connection
print_title "Testing Database Connection"
RDS_HOST=${RDS_DB_HOST:-}
if [ -z "$RDS_HOST" ]; then
    print_warning "RDS_DB_HOST not set"
else
    if mysql -h "$RDS_HOST" -u "${RDS_DB_USER:-admin}" -p"${RDS_DB_PASSWORD}" -e "SELECT 1;" &>/dev/null; then
        print_ok "Database connection successful"
    else
        print_error "Database connection failed"
        echo "Common reasons:"
        echo "  1. Security group not allowing port 3306"
        echo "  2. Wrong RDS endpoint or credentials"
        echo "  3. RDS instance not running"
    fi
fi
echo ""

# 6. Check CloudWatch Logs
print_title "Checking CloudWatch Logs"
LOG_GROUPS=$(aws logs describe-log-groups \
    --region $REGION \
    --query 'logGroups[?contains(logGroupName, `elasticbeanstalk`)].logGroupName' \
    --output text 2>/dev/null || echo "")

if [ -z "$LOG_GROUPS" ]; then
    print_warning "No CloudWatch log groups found"
else
    print_ok "CloudWatch log groups found:"
    echo "$LOG_GROUPS" | tr '\t' '\n'
fi
echo ""

# 7. Check SNS Topic
print_title "Checking SNS Notifications"
SNS_TOPICS=$(aws sns list-topics \
    --region $REGION \
    --query 'Topics[?contains(TopicArn, `library`)].TopicArn' \
    --output text 2>/dev/null || echo "")

if [ -z "$SNS_TOPICS" ]; then
    print_warning "No library SNS topics found"
else
    print_ok "SNS topics found:"
    echo "$SNS_TOPICS" | tr '\t' '\n'
fi
echo ""

# 8. Check S3 Deployment Bucket
print_title "Checking S3 Deployment Buckets"
S3_BUCKETS=$(aws s3api list-buckets \
    --region $REGION \
    --query 'Buckets[?contains(Name, `library`)].Name' \
    --output text 2>/dev/null || echo "")

if [ -z "$S3_BUCKETS" ]; then
    print_warning "No library S3 buckets found"
else
    print_ok "S3 buckets found:"
    echo "$S3_BUCKETS" | tr '\t' '\n'
fi
echo ""

# 9. Check Recent Events
print_title "Recent Elastic Beanstalk Events"
if eb events --region $REGION 2>/dev/null | head -5; then
    echo "✓ Last 5 events retrieved"
fi
echo ""

# 10. Check Application Logs
print_title "Recent Application Logs"
if eb logs --region $REGION 2>/dev/null | tail -20; then
    echo "✓ Last 20 log lines retrieved"
fi
echo ""

echo "========================================="
echo "Troubleshooting Complete"
echo "========================================="
echo ""
echo "Common Issues & Solutions:"
echo ""
echo "1. DATABASE CONNECTION ERRORS"
echo "   - Check RDS security group allows port 3306"
echo "   - Verify credentials in environment variables"
echo "   - Ensure RDS instance is in 'available' state"
echo "   - Test: mysql -h \$RDS_DB_HOST -u admin -p"
echo ""
echo "2. DEPLOYMENT FAILURES"
echo "   - View logs: eb logs -z"
echo "   - Check health: eb health --refresh"
echo "   - Review CloudWatch: aws logs tail /aws/elasticbeanstalk/..."
echo ""
echo "3. PERMISSION DENIED"
echo "   - Verify IAM role has necessary permissions"
echo "   - Check .ebextensions/04-iam.config"
echo "   - Re-deploy: eb deploy"
echo ""
echo "4. SLOW PERFORMANCE"
echo "   - Check CloudWatch metrics"
echo "   - Scale up: eb scale 2"
echo "   - Monitor: eb health --refresh"
echo ""
echo "5. SNS NOT SENDING"
echo "   - Verify SNS topic ARN in environment"
echo "   - Check email subscriptions confirmed"
echo "   - Test: aws sns publish --topic-arn ... --message 'test'"
echo ""
echo "For detailed help, see DEPLOYMENT-GUIDE.md"
