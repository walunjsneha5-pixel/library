#!/bin/bash

##############################################################################
# Quick Deployment Script for AWS Elastic Beanstalk
# Create and deploy the application to AWS EB
##############################################################################

set -e

# Configuration
APP_NAME=${1:-library-app}
ENV_NAME=${2:-library-app-env}
REGION=${AWS_REGION:-us-east-1}

echo "========================================="
echo "AWS Elastic Beanstalk Deployment"
echo "========================================="
echo "Application: $APP_NAME"
echo "Environment: $ENV_NAME"
echo "Region: $REGION"
echo ""

# Create EB environment if it doesn't exist
echo "[Step 1] Creating/Updating Elastic Beanstalk environment..."
eb create $ENV_NAME \
    --instance-type t3.micro \
    --single \
    --scale 1 \
    --region $REGION \
    --envvars \
    RDS_DB_HOST=${RDS_DB_HOST},\
    RDS_DB_USER=${RDS_DB_USER},\
    RDS_DB_PASSWORD=${RDS_DB_PASSWORD},\
    RDS_DB_NAME=library,\
    APP_ENV=production,\
    APP_DEBUG=false,\
    ENABLE_CLOUDWATCH=true \
    2>/dev/null || echo "Environment might already exist"

echo "[Step 2] Deploying application..."
eb deploy --region $REGION

echo "[Step 3] Waiting for deployment..."
sleep 30

echo "[Step 4] Checking health..."
eb health --region $REGION

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="

# Get environment URL
ENVIRONMENT_URL=$(aws elasticbeanstalk describe-environments \
    --application-name $APP_NAME \
    --environment-names $ENV_NAME \
    --region $REGION \
    --query 'Environments[0].CNAME' \
    --output text)

echo "Application URL: http://$ENVIRONMENT_URL"
echo ""
echo "Useful commands:"
echo "  eb open                          - Open application in browser"
echo "  eb logs -z                       - View application logs"
echo "  eb health --refresh              - Monitor application health"
echo "  eb terminate                     - Delete environment"
echo ""
