# Gemini Runtime Deployment

This directory contains everything needed to deploy the Gemini emergency detection system to AWS CloudFront + Lambda.

## Quick Start

```powershell
# From project root
cd Gemini3_AllSensesAI

# Deploy (one command)
.\deployment\deploy-gemini-runtime.ps1

# Validate
.\deployment\validate-gemini-runtime.ps1
```

**Time**: 5-7 minutes  
**Output**: CloudFront HTTPS URL

---

## Directory Structure

```
deployment/
├── gemini-runtime-cloudfront.yaml    # CloudFormation template
├── deploy-gemini-runtime.ps1         # Deployment script
├── validate-gemini-runtime.ps1       # Validation script
├── lambda/
│   ├── gemini_handler.py             # Lambda handler
│   └── requirements.txt              # Python dependencies
├── ui/
│   └── index.html                    # CloudFront UI
└── README.md                         # This file
```

---

## Prerequisites

1. **AWS CLI** configured with credentials
2. **Python 3.11+** installed
3. **Gemini API Key** in `.env` file at project root:
   ```
   GOOGLE_GEMINI_API_KEY=your_api_key_here
   GEMINI_MODEL=gemini-1.5-pro
   ```

---

## Deployment

### Automated (Recommended)

```powershell
.\deployment\deploy-gemini-runtime.ps1
```

This script will:
1. Check prerequisites
2. Store API key in SSM Parameter Store
3. Package Lambda function
4. Deploy CloudFormation stack
5. Update Lambda code
6. Deploy UI to S3
7. Invalidate CloudFront cache
8. Display deployment URLs

### Manual

See `../DEPLOY_GEMINI_RUNTIME.md` for step-by-step manual deployment.

---

## Validation

```powershell
.\deployment\validate-gemini-runtime.ps1
```

Tests:
- Lambda health endpoint
- Lambda analysis endpoint
- CloudFront UI accessibility
- HTTPS and CORS configuration

---

## Files

### CloudFormation Template
**File**: `gemini-runtime-cloudfront.yaml`

Creates:
- S3 bucket for UI assets
- CloudFront distribution with HTTPS
- Lambda function with Function URL
- IAM roles and policies
- SSM Parameter Store integration

### Lambda Handler
**File**: `lambda/gemini_handler.py`

Provides:
- `/health` endpoint - Runtime health check
- `/analyze` endpoint - Emergency analysis
- Gemini API integration
- Fallback keyword matching
- CORS support

### CloudFront UI
**File**: `ui/index.html`

Features:
- Runtime health panel
- 5-step emergency pipeline
- Gemini analysis interface
- Console logging
- Architecture parity notes

### Deployment Script
**File**: `deploy-gemini-runtime.ps1`

Automates:
- Prerequisite checking
- API key storage
- Lambda packaging
- Stack deployment
- UI deployment
- Cache invalidation

### Validation Script
**File**: `validate-gemini-runtime.ps1`

Tests:
- Lambda endpoints
- CloudFront accessibility
- HTTPS configuration
- CORS headers

---

## Outputs

After deployment, you'll get:

- **CloudFront URL**: HTTPS URL for jury demo
- **Lambda Function URL**: Backend API endpoint
- **S3 Bucket**: UI assets bucket name
- **Distribution ID**: CloudFront distribution ID
- **Lambda ARN**: Lambda function ARN

All outputs are saved to `deployment-info.json`.

---

## Usage

### View Deployment Info
```powershell
Get-Content deployment/deployment-info.json | ConvertFrom-Json
```

### View Lambda Logs
```powershell
aws logs tail /aws/lambda/allsensesai-gemini-analysis --follow
```

### Invalidate CloudFront Cache
```powershell
$info = Get-Content deployment/deployment-info.json | ConvertFrom-Json
aws cloudfront create-invalidation --distribution-id $info.distributionId --paths "/*"
```

### Update Lambda Code
```powershell
# After modifying lambda/gemini_handler.py
.\deployment\deploy-gemini-runtime.ps1
```

---

## Troubleshooting

See `../TROUBLESHOOTING_GEMINI_RUNTIME.md` for common issues and solutions.

### Quick Fixes

**Lambda returns 500:**
```powershell
# Check API key
aws ssm get-parameter --name "/allsensesai/gemini/api-key" --with-decryption
```

**CloudFront shows old content:**
```powershell
# Invalidate cache
aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/*"
```

**Runtime Health shows FALLBACK:**
```powershell
# Check Lambda logs
aws logs tail /aws/lambda/allsensesai-gemini-analysis --follow
```

---

## Architecture

```
Browser (HTTPS)
    ↓
CloudFront Distribution
    ↓
S3 Bucket (UI)
    ↓ (API calls)
Lambda Function URL
    ↓
Gemini API (Google)
```

**Key Features:**
- HTTPS for GPS access
- Lambda Function URL (public, CORS-enabled)
- SSM Parameter Store (encrypted API key)
- Runtime health panel (LIVE/FALLBACK status)
- Fallback to keyword matching

---

## Cost

**Monthly costs for demo usage:**
- CloudFront: $1-5
- Lambda: $0-2
- S3: $0.50
- SSM: Free
- Gemini API: Free (60 req/min)

**Total**: $1-8/month

---

## Security

- API key encrypted in SSM Parameter Store
- HTTPS only (CloudFront enforces)
- CORS configured for browser access
- IAM roles with minimal permissions
- Lambda timeout protection (30s)

---

## Cleanup

```powershell
# Delete stack
aws cloudformation delete-stack --stack-name allsensesai-gemini-runtime

# Delete API key
aws ssm delete-parameter --name "/allsensesai/gemini/api-key"

# Clean local files
Remove-Item deployment/lambda-package -Recurse -Force
Remove-Item deployment/lambda-package.zip -Force
Remove-Item deployment/deployment-info.json -Force
```

---

## Documentation

- **DEPLOY_GEMINI_RUNTIME.md** - Complete deployment guide
- **JURY_DEMO_CLOUDFRONT.md** - Quick reference for jury
- **TROUBLESHOOTING_GEMINI_RUNTIME.md** - Common issues
- **CLOUDFRONT_DEPLOYMENT_COMPLETE.md** - Technical summary

---

## Support

For issues:
1. Check `../TROUBLESHOOTING_GEMINI_RUNTIME.md`
2. Run `validate-gemini-runtime.ps1`
3. View Lambda logs
4. Check `deployment-info.json`

---

**Status**: ✅ Ready for deployment  
**Time**: 5-7 minutes  
**Output**: CloudFront HTTPS URL
