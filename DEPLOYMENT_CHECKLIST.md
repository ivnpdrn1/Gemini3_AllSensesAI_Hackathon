# Gemini CloudFront Deployment Checklist

Use this checklist to ensure a smooth deployment and jury demonstration.

---

## Pre-Deployment Checklist

### Prerequisites
- [ ] AWS CLI installed and configured
  ```powershell
  aws --version
  aws configure list
  ```

- [ ] Python 3.11+ installed
  ```powershell
  python --version
  ```

- [ ] Gemini API key obtained from Google AI Studio
  - Visit: https://aistudio.google.com/app/apikey
  - Create new API key
  - Copy key value

- [ ] `.env` file created in project root
  ```
  GOOGLE_GEMINI_API_KEY=your_api_key_here
  GEMINI_MODEL=gemini-1.5-pro
  ```

- [ ] AWS credentials have required permissions:
  - CloudFormation
  - S3
  - Lambda
  - CloudFront
  - SSM Parameter Store
  - IAM

---

## Deployment Checklist

### Step 1: Run Deployment Script
- [ ] Navigate to project directory
  ```powershell
  cd Gemini3_AllSensesAI
  ```

- [ ] Run deployment script
  ```powershell
  .\deployment\deploy-gemini-runtime.ps1
  ```

- [ ] Wait for completion (5-7 minutes)

- [ ] Note CloudFront URL from output

- [ ] Note Lambda Function URL from output

### Step 2: Verify Deployment
- [ ] Run validation script
  ```powershell
  .\deployment\validate-gemini-runtime.ps1
  ```

- [ ] All 4 tests pass:
  - [ ] Lambda health check
  - [ ] Lambda analysis endpoint
  - [ ] CloudFront UI accessibility
  - [ ] HTTPS and CORS

### Step 3: Check Deployment Info
- [ ] Review deployment info file
  ```powershell
  Get-Content deployment/deployment-info.json | ConvertFrom-Json
  ```

- [ ] Verify all outputs present:
  - [ ] cloudFrontUrl
  - [ ] lambdaFunctionUrl
  - [ ] s3Bucket
  - [ ] distributionId
  - [ ] lambdaArn

---

## Pre-Demo Checklist

### Browser Testing
- [ ] Open CloudFront URL in browser

- [ ] Verify HTTPS in address bar (GPS-enabled)

- [ ] Check Runtime Health Panel shows:
  - [ ] Gemini Client: LIVE (green) or FALLBACK (yellow)
  - [ ] Model: gemini-1.5-pro
  - [ ] SDK Available: Yes or No
  - [ ] Mode: LIVE or FALLBACK
  - [ ] Backend: Lambda
  - [ ] Deployment: CloudFront

### Functional Testing
- [ ] Test HIGH risk scenario:
  ```
  Help me please, I don't feel safe. There's someone following me and I'm scared.
  ```
  - [ ] Risk Level: HIGH
  - [ ] Confidence: 80-90%
  - [ ] Mode: LIVE (if Gemini available)
  - [ ] Indicators: help_request, fear, stalking

- [ ] Test MEDIUM risk scenario:
  ```
  I'm feeling uncomfortable in this situation. Not sure what to do.
  ```
  - [ ] Risk Level: MEDIUM
  - [ ] Confidence: 60-70%

- [ ] Test LOW risk scenario:
  ```
  Everything is fine, just checking in. No issues here.
  ```
  - [ ] Risk Level: LOW or NONE
  - [ ] Confidence: 30-40%

### Console Verification
- [ ] Open browser console (F12)

- [ ] Check for initialization logs:
  ```
  [GEMINI-CLOUDFRONT] System initializing...
  [GEMINI-CLOUDFRONT] Gemini SDK detected and initialized
  [GEMINI-CLOUDFRONT] Model: gemini-1.5-pro
  ```

- [ ] Check for analysis logs:
  ```
  [GEMINI-CLOUDFRONT] Analysis complete: HIGH (confidence: 0.85)
  ```

---

## Jury Demo Checklist

### Preparation (5 minutes before)
- [ ] Open CloudFront URL in browser

- [ ] Verify Runtime Health shows LIVE status

- [ ] Prepare HIGH risk transcript in clipboard

- [ ] Open browser console (F12) for logs

- [ ] Have troubleshooting commands ready

### Demo Flow (5 minutes)
- [ ] **Intro** (30 seconds)
  - Show CloudFront URL (HTTPS)
  - Point out "CloudFront + Lambda" subtitle

- [ ] **Runtime Health** (1 minute)
  - Walk through health panel
  - Explain LIVE vs FALLBACK
  - Show model name (gemini-1.5-pro)

- [ ] **Pipeline Overview** (1 minute)
  - Walk through 5 steps
  - Explain each step briefly
  - Emphasize architectural parity with ERNIE

- [ ] **Live Analysis** (2 minutes)
  - Paste HIGH risk transcript
  - Click "Analyze with Gemini"
  - Show result panel
  - Explain risk level, confidence, indicators

- [ ] **Console Logs** (30 seconds)
  - Scroll to console log panel
  - Show audit trail
  - Explain runtime proof

### Key Talking Points
- [ ] "Complete architectural parity with ERNIE"
- [ ] "Gemini 1.5 Pro provides intelligence layer"
- [ ] "Runtime proof shows LIVE status, not mocked"
- [ ] "System fails safely to keyword matching if Gemini unavailable"
- [ ] "Deployed on AWS CloudFront + Lambda for production reliability"

---

## Troubleshooting Checklist

### If Runtime Health Shows FALLBACK
- [ ] Check Lambda logs:
  ```powershell
  aws logs tail /aws/lambda/allsensesai-gemini-analysis --follow
  ```

- [ ] Verify API key in SSM:
  ```powershell
  aws ssm get-parameter --name "/allsensesai/gemini/api-key" --with-decryption
  ```

- [ ] Check Gemini API status:
  - Visit: https://status.cloud.google.com/

### If CloudFront Shows Old Content
- [ ] Invalidate cache:
  ```powershell
  $info = Get-Content deployment/deployment-info.json | ConvertFrom-Json
  aws cloudfront create-invalidation --distribution-id $info.distributionId --paths "/*"
  ```

- [ ] Wait 1-2 minutes for invalidation

- [ ] Hard refresh browser (Ctrl+Shift+R)

### If Lambda Returns 500 Error
- [ ] Check Lambda logs for errors

- [ ] Verify API key is valid

- [ ] Check Lambda function configuration:
  ```powershell
  aws lambda get-function-configuration --function-name allsensesai-gemini-analysis
  ```

### If CORS Errors in Browser
- [ ] Verify Lambda Function URL CORS:
  ```powershell
  aws lambda get-function-url-config --function-name allsensesai-gemini-analysis
  ```

- [ ] Redeploy if CORS missing:
  ```powershell
  .\deployment\deploy-gemini-runtime.ps1
  ```

---

## Post-Demo Checklist

### Cleanup (Optional)
- [ ] Delete CloudFormation stack:
  ```powershell
  aws cloudformation delete-stack --stack-name allsensesai-gemini-runtime
  ```

- [ ] Delete SSM parameter:
  ```powershell
  aws ssm delete-parameter --name "/allsensesai/gemini/api-key"
  ```

- [ ] Clean local files:
  ```powershell
  Remove-Item deployment/lambda-package -Recurse -Force
  Remove-Item deployment/lambda-package.zip -Force
  Remove-Item deployment/deployment-info.json -Force
  ```

### Keep Running (Recommended)
- [ ] Monitor costs in AWS Cost Explorer

- [ ] Set up CloudWatch alarms for Lambda errors

- [ ] Review Lambda logs periodically

---

## Emergency Contacts

### Documentation
- [ ] `DEPLOY_GEMINI_RUNTIME.md` - Complete deployment guide
- [ ] `JURY_DEMO_CLOUDFRONT.md` - Quick reference
- [ ] `TROUBLESHOOTING_GEMINI_RUNTIME.md` - Common issues

### Commands
```powershell
# View deployment info
Get-Content deployment/deployment-info.json

# View Lambda logs
aws logs tail /aws/lambda/allsensesai-gemini-analysis --follow

# Run validation
.\deployment\validate-gemini-runtime.ps1

# Invalidate cache
aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/*"
```

### Resources
- AWS Console: https://console.aws.amazon.com/
- Google AI Studio: https://aistudio.google.com/
- Gemini Status: https://status.cloud.google.com/

---

## Success Criteria

All items must be checked:

- [ ] CloudFront URL accessible via HTTPS
- [ ] Runtime Health panel shows LIVE status
- [ ] Gemini analysis returns structured JSON
- [ ] HIGH risk scenarios trigger alerts
- [ ] Console logs show audit trail
- [ ] Fallback mode works if Gemini unavailable
- [ ] Validation script passes all tests
- [ ] Demo runs smoothly (5 minutes)
- [ ] All talking points covered
- [ ] Troubleshooting commands ready

---

**Status**: Ready for deployment  
**Estimated Time**: 20-25 minutes (deployment + validation + demo prep)  
**Jury Demo Duration**: 5 minutes  
**Q&A Buffer**: 5-10 minutes
