# Gemini Runtime Troubleshooting Guide

## Common Issues and Solutions

### 1. Deployment Fails: "API key not found in .env"

**Symptom:**
```
ERROR: GOOGLE_GEMINI_API_KEY not found in .env
```

**Cause:** Missing or incorrectly formatted `.env` file

**Solution:**
```powershell
# Create .env file in project root
cd Gemini3_AllSensesAI
New-Item -ItemType File -Path .env

# Add API key
Add-Content .env "GOOGLE_GEMINI_API_KEY=your_api_key_here"
Add-Content .env "GEMINI_MODEL=gemini-1.5-pro"

# Verify
Get-Content .env
```

---

### 2. Lambda Returns 500 Error

**Symptom:**
```json
{
  "statusCode": 500,
  "body": "{\"error\": \"Failed to retrieve API key\"}"
}
```

**Cause:** API key not in SSM Parameter Store or Lambda lacks permissions

**Solution:**

**Check if parameter exists:**
```powershell
aws ssm get-parameter --name "/allsensesai/gemini/api-key" --with-decryption --region us-east-1
```

**If not found, create it:**
```powershell
aws ssm put-parameter `
    --name "/allsensesai/gemini/api-key" `
    --value "YOUR_API_KEY" `
    --type "SecureString" `
    --region us-east-1
```

**Check Lambda logs:**
```powershell
aws logs tail /aws/lambda/allsensesai-gemini-analysis --follow --region us-east-1
```

---

### 3. Runtime Health Shows FALLBACK Mode

**Symptom:** UI shows "Gemini Client: FALLBACK" instead of "LIVE"

**Possible Causes:**
1. Invalid API key
2. Gemini API quota exceeded
3. Network connectivity issue
4. SDK not installed in Lambda

**Diagnosis:**

**Check Lambda logs:**
```powershell
aws logs tail /aws/lambda/allsensesai-gemini-analysis --follow
```

Look for:
- `"Failed to initialize Gemini: ..."`
- `"Gemini API error: ..."`
- `"google-generativeai SDK not available"`

**Solutions:**

**Invalid API Key:**
```powershell
# Get new API key from Google AI Studio
# Update parameter
aws ssm put-parameter `
    --name "/allsensesai/gemini/api-key" `
    --value "NEW_API_KEY" `
    --type "SecureString" `
    --overwrite `
    --region us-east-1
```

**Quota Exceeded:**
- Check quota at: https://aistudio.google.com/app/apikey
- Wait for quota reset (typically 1 minute)
- Consider upgrading to paid tier

**SDK Not Installed:**
```powershell
# Redeploy Lambda with dependencies
.\deployment\deploy-gemini-runtime.ps1
```

---

### 4. CloudFront Shows Old Content

**Symptom:** UI changes not visible after deployment

**Cause:** CloudFront cache not invalidated

**Solution:**

**Get distribution ID:**
```powershell
$deploymentInfo = Get-Content deployment/deployment-info.json | ConvertFrom-Json
$distributionId = $deploymentInfo.distributionId
```

**Create invalidation:**
```powershell
aws cloudfront create-invalidation `
    --distribution-id $distributionId `
    --paths "/*" `
    --region us-east-1
```

**Check invalidation status:**
```powershell
aws cloudfront list-invalidations --distribution-id $distributionId
```

Wait 1-2 minutes for completion.

---

### 5. CORS Errors in Browser Console

**Symptom:**
```
Access to fetch at 'https://...' from origin 'https://...' has been blocked by CORS policy
```

**Cause:** Lambda Function URL CORS not configured

**Solution:**

**Verify CORS configuration:**
```powershell
aws lambda get-function-url-config `
    --function-name allsensesai-gemini-analysis `
    --region us-east-1
```

Should show:
```json
{
  "Cors": {
    "AllowOrigins": ["*"],
    "AllowMethods": ["POST", "GET", "OPTIONS"],
    "AllowHeaders": ["Content-Type"]
  }
}
```

**If missing, redeploy stack:**
```powershell
.\deployment\deploy-gemini-runtime.ps1
```

---

### 6. Lambda Timeout (30 seconds)

**Symptom:**
```json
{
  "errorType": "Task timed out after 30.00 seconds"
}
```

**Cause:** Gemini API slow or unresponsive

**Solution:**

**Increase Lambda timeout:**
```powershell
aws lambda update-function-configuration `
    --function-name allsensesai-gemini-analysis `
    --timeout 60 `
    --region us-east-1
```

**Check Gemini API status:**
- Visit: https://status.cloud.google.com/

---

### 7. S3 Upload Fails: "Access Denied"

**Symptom:**
```
An error occurred (AccessDenied) when calling the PutObject operation
```

**Cause:** Insufficient S3 permissions

**Solution:**

**Check bucket policy:**
```powershell
$bucketName = (Get-Content deployment/deployment-info.json | ConvertFrom-Json).s3Bucket
aws s3api get-bucket-policy --bucket $bucketName
```

**Update bucket policy if needed:**
```powershell
aws s3api put-bucket-policy `
    --bucket $bucketName `
    --policy file://deployment/bucket-policy.json
```

---

### 8. CloudFormation Stack Fails to Create

**Symptom:**
```
CREATE_FAILED: Resource creation cancelled
```

**Diagnosis:**

**Check stack events:**
```powershell
aws cloudformation describe-stack-events `
    --stack-name allsensesai-gemini-runtime `
    --region us-east-1 `
    --max-items 20
```

**Common causes:**
1. IAM permissions insufficient
2. Resource limits exceeded
3. Invalid parameter values

**Solution:**

**Delete failed stack:**
```powershell
aws cloudformation delete-stack `
    --stack-name allsensesai-gemini-runtime `
    --region us-east-1
```

**Wait for deletion:**
```powershell
aws cloudformation wait stack-delete-complete `
    --stack-name allsensesai-gemini-runtime `
    --region us-east-1
```

**Retry deployment:**
```powershell
.\deployment\deploy-gemini-runtime.ps1
```

---

### 9. Lambda Package Too Large

**Symptom:**
```
InvalidParameterValueException: Unzipped size must be smaller than 262144000 bytes
```

**Cause:** Lambda deployment package exceeds 250MB limit

**Solution:**

**Check package size:**
```powershell
$zipSize = (Get-Item deployment/lambda-package.zip).Length / 1MB
Write-Host "Package size: $zipSize MB"
```

**If too large, use Lambda layers:**
```powershell
# Create layer for dependencies
pip install --target layer/python google-generativeai python-dotenv

# Create layer zip
Compress-Archive -Path layer/* -DestinationPath gemini-layer.zip

# Publish layer
aws lambda publish-layer-version `
    --layer-name gemini-dependencies `
    --zip-file fileb://gemini-layer.zip `
    --compatible-runtimes python3.11
```

---

### 10. Gemini Returns Invalid JSON

**Symptom:**
```
Failed to parse Gemini response: Expecting value: line 1 column 1 (char 0)
```

**Cause:** Gemini returned non-JSON response (rare)

**Solution:**

**Check Lambda logs for raw response:**
```powershell
aws logs tail /aws/lambda/allsensesai-gemini-analysis --follow
```

**Adjust prompt if needed:**
Edit `deployment/lambda/gemini_handler.py`:
```python
# Add more explicit JSON instruction
prompt += "\n\nIMPORTANT: Respond ONLY with valid JSON. No markdown, no explanations."
```

**Redeploy:**
```powershell
.\deployment\deploy-gemini-runtime.ps1
```

---

## Diagnostic Commands

### Check Deployment Status
```powershell
aws cloudformation describe-stacks `
    --stack-name allsensesai-gemini-runtime `
    --region us-east-1 `
    --query "Stacks[0].StackStatus"
```

### View Lambda Logs (Last 10 minutes)
```powershell
aws logs tail /aws/lambda/allsensesai-gemini-analysis `
    --since 10m `
    --region us-east-1
```

### Test Lambda Directly
```powershell
aws lambda invoke `
    --function-name allsensesai-gemini-analysis `
    --payload '{"requestContext":{"http":{"method":"GET","path":"/health"}}}' `
    --region us-east-1 `
    response.json

Get-Content response.json
```

### Check CloudFront Distribution Status
```powershell
$distributionId = (Get-Content deployment/deployment-info.json | ConvertFrom-Json).distributionId
aws cloudfront get-distribution --id $distributionId --query "Distribution.Status"
```

### Verify SSM Parameter
```powershell
aws ssm get-parameter `
    --name "/allsensesai/gemini/api-key" `
    --with-decryption `
    --region us-east-1 `
    --query "Parameter.Value" `
    --output text
```

---

## Emergency Recovery

### Complete Redeployment

If all else fails, perform a complete redeployment:

```powershell
# 1. Delete stack
aws cloudformation delete-stack `
    --stack-name allsensesai-gemini-runtime `
    --region us-east-1

# 2. Wait for deletion
aws cloudformation wait stack-delete-complete `
    --stack-name allsensesai-gemini-runtime `
    --region us-east-1

# 3. Delete parameter
aws ssm delete-parameter `
    --name "/allsensesai/gemini/api-key" `
    --region us-east-1

# 4. Clean local files
Remove-Item deployment/lambda-package -Recurse -Force
Remove-Item deployment/lambda-package.zip -Force
Remove-Item deployment/deployment-info.json -Force

# 5. Redeploy
.\deployment\deploy-gemini-runtime.ps1
```

---

## Getting Help

### Check Logs
```powershell
# Lambda logs
aws logs tail /aws/lambda/allsensesai-gemini-analysis --follow

# CloudFormation events
aws cloudformation describe-stack-events --stack-name allsensesai-gemini-runtime --max-items 20
```

### Validation Script
```powershell
.\deployment\validate-gemini-runtime.ps1
```

### Deployment Info
```powershell
Get-Content deployment/deployment-info.json | ConvertFrom-Json | Format-List
```

### AWS Support
- CloudFormation: https://console.aws.amazon.com/cloudformation
- Lambda: https://console.aws.amazon.com/lambda
- CloudFront: https://console.aws.amazon.com/cloudfront

### Gemini Support
- API Status: https://status.cloud.google.com/
- Documentation: https://ai.google.dev/docs
- API Keys: https://aistudio.google.com/app/apikey
