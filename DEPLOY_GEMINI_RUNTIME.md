# Gemini Runtime Deployment Guide
## CloudFront + Lambda Function URL Architecture

This guide covers deploying the Gemini emergency detection system to AWS using CloudFront for the UI and Lambda Function URL for the backend API.

## Architecture Overview

```
┌─────────────┐
│   Browser   │
│  (Jury/User)│
└──────┬──────┘
       │ HTTPS (GPS-enabled)
       ▼
┌─────────────────┐
│   CloudFront    │ ← S3 bucket (UI assets)
│  Distribution   │
└──────┬──────────┘
       │ API calls
       ▼
┌─────────────────┐
│ Lambda Function │ ← Gemini API
│   Function URL  │ ← SSM Parameter (API key)
└─────────────────┘
```

## Prerequisites

1. **AWS Account** with appropriate permissions:
   - CloudFormation
   - S3
   - Lambda
   - CloudFront
   - SSM Parameter Store
   - IAM

2. **AWS CLI** installed and configured:
   ```powershell
   aws --version
   aws configure
   ```

3. **Python 3.11+** installed:
   ```powershell
   python --version
   ```

4. **Gemini API Key** from Google AI Studio:
   - Visit: https://aistudio.google.com/app/apikey
   - Create new API key
   - Add to `.env` file:
     ```
     GOOGLE_GEMINI_API_KEY=your_api_key_here
     GEMINI_MODEL=gemini-1.5-pro
     ```

## One-Command Deployment

From the project root directory:

```powershell
.\Gemini3_AllSensesAI\deployment\deploy-gemini-runtime.ps1
```

This script will:
1. Check prerequisites (AWS CLI, Python, .env file)
2. Store API key in SSM Parameter Store (encrypted)
3. Package Lambda function with dependencies
4. Deploy CloudFormation stack (S3, CloudFront, Lambda)
5. Update Lambda function code
6. Deploy UI to S3 with Lambda URL configured
7. Invalidate CloudFront cache
8. Display deployment URLs

## Deployment Steps (Manual)

If you prefer manual deployment:

### Step 1: Store API Key in Parameter Store

```powershell
aws ssm put-parameter `
    --name "/allsensesai/gemini/api-key" `
    --value "YOUR_API_KEY" `
    --type "SecureString" `
    --region us-east-1
```

### Step 2: Package Lambda Function

```powershell
cd Gemini3_AllSensesAI

# Create package directory
New-Item -ItemType Directory -Path deployment/lambda-package

# Copy Lambda handler
Copy-Item deployment/lambda/gemini_handler.py deployment/lambda-package/

# Copy Gemini client
Copy-Item src/gemini/client.py deployment/lambda-package/

# Install dependencies
pip install --target deployment/lambda-package google-generativeai python-dotenv boto3

# Create zip file
Compress-Archive -Path deployment/lambda-package/* -DestinationPath deployment/lambda-package.zip
```

### Step 3: Deploy CloudFormation Stack

```powershell
aws cloudformation deploy `
    --template-file deployment/gemini-runtime-cloudfront.yaml `
    --stack-name allsensesai-gemini-runtime `
    --capabilities CAPABILITY_IAM `
    --region us-east-1 `
    --parameter-overrides `
        GeminiApiKeyParameter="/allsensesai/gemini/api-key" `
        GeminiModel="gemini-1.5-pro"
```

### Step 4: Update Lambda Function Code

```powershell
aws lambda update-function-code `
    --function-name allsensesai-gemini-analysis `
    --zip-file fileb://deployment/lambda-package.zip `
    --region us-east-1
```

### Step 5: Get Stack Outputs

```powershell
aws cloudformation describe-stacks `
    --stack-name allsensesai-gemini-runtime `
    --region us-east-1 `
    --query "Stacks[0].Outputs"
```

Note the following outputs:
- `CloudFrontUrl`: HTTPS URL for jury demo
- `LambdaFunctionUrl`: Backend API endpoint
- `S3BucketName`: UI assets bucket
- `DistributionId`: CloudFront distribution ID

### Step 6: Deploy UI to S3

```powershell
# Replace Lambda URL placeholder in index.html
$lambdaUrl = "YOUR_LAMBDA_FUNCTION_URL"
$html = Get-Content deployment/ui/index.html -Raw
$html = $html -replace '\{\{LAMBDA_FUNCTION_URL\}\}', $lambdaUrl
$html | Out-File deployment/ui/index-deployed.html -Encoding UTF8

# Upload to S3
aws s3 cp deployment/ui/index-deployed.html s3://YOUR_BUCKET_NAME/index.html `
    --content-type "text/html" `
    --region us-east-1
```

### Step 7: Invalidate CloudFront Cache

```powershell
aws cloudfront create-invalidation `
    --distribution-id YOUR_DISTRIBUTION_ID `
    --paths "/*" `
    --region us-east-1
```

## Validation

Run the validation script to test the deployment:

```powershell
.\Gemini3_AllSensesAI\deployment\validate-gemini-runtime.ps1
```

This will test:
1. Lambda health endpoint
2. Lambda analysis endpoint
3. CloudFront UI accessibility
4. HTTPS and CORS configuration

## Testing the Deployment

### 1. Open CloudFront URL

Open the CloudFront URL in your browser (from deployment output).

### 2. Check Runtime Health Panel

The UI should display:
- **Gemini Client**: LIVE or FALLBACK
- **Model**: gemini-1.5-pro
- **SDK Available**: Yes or No
- **Mode**: LIVE or FALLBACK
- **Backend**: Lambda
- **Deployment**: CloudFront

### 3. Test Emergency Analysis

Use these sample transcripts:

**HIGH RISK:**
```
Help me please, I don't feel safe. There's someone following me and I'm scared.
```

**MEDIUM RISK:**
```
I'm feeling uncomfortable in this situation. Not sure what to do.
```

**LOW RISK:**
```
Everything is fine, just checking in. No issues here.
```

### 4. Verify Console Logs

Open browser console (F12) and check for:
- `[GEMINI-CLOUDFRONT] System initializing...`
- `[GEMINI-CLOUDFRONT] Gemini SDK detected and initialized`
- `[GEMINI-CLOUDFRONT] Analysis complete: HIGH (confidence: 0.85)`

## Architecture Parity with ERNIE

This deployment mirrors the ERNIE CloudFront architecture:

| Component | ERNIE | Gemini |
|-----------|-------|--------|
| UI Hosting | S3 + CloudFront | S3 + CloudFront |
| Backend | Lambda Function URL | Lambda Function URL |
| AI Provider | ERNIE (Baidu) | Gemini (Google) |
| API Key Storage | SSM Parameter Store | SSM Parameter Store |
| HTTPS | CloudFront default cert | CloudFront default cert |
| GPS Access | HTTPS enabled | HTTPS enabled |
| Fallback | Keyword matching | Keyword matching |

## Troubleshooting

### Lambda Returns 500 Error

**Cause**: API key not found or invalid

**Solution**:
```powershell
# Verify parameter exists
aws ssm get-parameter --name "/allsensesai/gemini/api-key" --with-decryption

# Update parameter
aws ssm put-parameter `
    --name "/allsensesai/gemini/api-key" `
    --value "YOUR_NEW_API_KEY" `
    --type "SecureString" `
    --overwrite
```

### CloudFront Shows Old Content

**Cause**: Cache not invalidated

**Solution**:
```powershell
aws cloudfront create-invalidation `
    --distribution-id YOUR_DISTRIBUTION_ID `
    --paths "/*"
```

Wait 1-2 minutes for invalidation to complete.

### Gemini Shows FALLBACK Mode

**Cause**: API key invalid or quota exceeded

**Solution**:
1. Check API key in Google AI Studio
2. Verify quota limits
3. Check Lambda logs:
   ```powershell
   aws logs tail /aws/lambda/allsensesai-gemini-analysis --follow
   ```

### CORS Errors in Browser

**Cause**: Lambda Function URL CORS not configured

**Solution**: Redeploy CloudFormation stack (CORS is configured in template)

## Cost Estimate

**Monthly costs for moderate usage:**

- **CloudFront**: ~$1-5 (first 1TB free tier)
- **Lambda**: ~$0-2 (1M requests free tier)
- **S3**: ~$0.50 (storage + requests)
- **SSM Parameter Store**: Free (standard parameters)
- **Gemini API**: Free tier (60 requests/minute)

**Total**: ~$1-8/month for demo usage

## Security Considerations

1. **API Key**: Stored encrypted in SSM Parameter Store
2. **HTTPS**: All traffic encrypted via CloudFront
3. **CORS**: Configured to allow browser access
4. **IAM**: Lambda has minimal permissions (SSM read-only)
5. **Public Access**: Lambda Function URL is public (no auth)

For production:
- Add API Gateway with authentication
- Implement rate limiting
- Add WAF rules to CloudFront
- Use custom domain with ACM certificate

## Cleanup

To delete all resources:

```powershell
# Delete CloudFormation stack
aws cloudformation delete-stack `
    --stack-name allsensesai-gemini-runtime `
    --region us-east-1

# Delete SSM parameter
aws ssm delete-parameter `
    --name "/allsensesai/gemini/api-key" `
    --region us-east-1

# Empty and delete S3 bucket (if needed)
aws s3 rm s3://YOUR_BUCKET_NAME --recursive
aws s3 rb s3://YOUR_BUCKET_NAME
```

## Next Steps

1. **Jury Presentation**: Use CloudFront URL for live demo
2. **Custom Domain**: Add Route53 + ACM certificate
3. **Monitoring**: Add CloudWatch dashboards
4. **Alerting**: Configure SNS for emergency notifications
5. **Production**: Add authentication and rate limiting

## Support

For issues or questions:
1. Check CloudWatch Logs: `/aws/lambda/allsensesai-gemini-analysis`
2. Review deployment info: `deployment/deployment-info.json`
3. Run validation script: `validate-gemini-runtime.ps1`
