#!/bin/bash
# Deployment script for AllSensesAI Gemini 3 Edition
# Original work created for Google Gemini 3 Hackathon 2026

set -e

echo "========================================="
echo "AllSensesAI Gemini 3 Edition Deployment"
echo "========================================="

# Configuration
STACK_NAME="allsensesai-gemini3"
REGION="us-east-1"
LAMBDA_FUNCTION_NAME="allsensesai-emergency-detector"
S3_BUCKET="allsensesai-deployment-artifacts"

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI not found. Please install AWS CLI."
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 not found. Please install Python 3."
    exit 1
fi

echo "Prerequisites OK"

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt -t ./lambda_package/

# Copy source code
echo "Copying source code..."
cp -r src/* ./lambda_package/

# Copy prompts
echo "Copying prompts..."
mkdir -p ./lambda_package/prompts
cp prompts/*.md prompts/*.json ./lambda_package/prompts/

# Package Lambda function
echo "Packaging Lambda function..."
cd lambda_package
zip -r ../lambda_function.zip .
cd ..

# Create S3 bucket if it doesn't exist
echo "Checking S3 bucket..."
if ! aws s3 ls "s3://${S3_BUCKET}" 2>&1 > /dev/null; then
    echo "Creating S3 bucket: ${S3_BUCKET}"
    aws s3 mb "s3://${S3_BUCKET}" --region ${REGION}
fi

# Upload Lambda package
echo "Uploading Lambda package to S3..."
aws s3 cp lambda_function.zip "s3://${S3_BUCKET}/lambda_function.zip"

# Deploy CloudFormation stack
echo "Deploying CloudFormation stack..."
aws cloudformation deploy \
    --template-file cloudformation.yaml \
    --stack-name ${STACK_NAME} \
    --parameter-overrides \
        LambdaCodeBucket=${S3_BUCKET} \
        LambdaCodeKey=lambda_function.zip \
    --capabilities CAPABILITY_IAM \
    --region ${REGION}

# Get outputs
echo "Retrieving stack outputs..."
API_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
    --output text \
    --region ${REGION})

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo "API Endpoint: ${API_ENDPOINT}"
echo ""
echo "Test the API:"
echo "curl -X POST ${API_ENDPOINT}/analyze \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"text\": \"Help me please\", \"context\": {}}'"
echo ""
