# Deploy SMS Backend for Gemini3 Guardian
# Deploys Lambda + API Gateway, updates HTML with endpoint, deploys to CloudFront

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Gemini3 Guardian - SMS Backend Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$STACK_NAME = "gemini3-sms-backend"
$TEMPLATE_FILE = "Gemini3_AllSensesAI/backend/sms/template.yaml"
$BUILD_SCRIPT = "Gemini3_AllSensesAI/create-jury-ready-video-sms-build.py"
$HTML_FILE = "Gemini3_AllSensesAI/gemini3-guardian-jury-ready-video-sms.html"
$S3_BUCKET = "gemini3-guardian-prod-20260127120521"
$CLOUDFRONT_DIST_ID = "E2NIUI2KOXAO0Q"
$ENVIRONMENT = "prod"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Stack Name: $STACK_NAME"
Write-Host "  Template: $TEMPLATE_FILE"
Write-Host "  S3 Bucket: $S3_BUCKET"
Write-Host "  CloudFront: $CLOUDFRONT_DIST_ID"
Write-Host ""

# Step 0: Check SNS Configuration
Write-Host "[0/7] Checking SNS configuration..." -ForegroundColor Green
& ".\Gemini3_AllSensesAI\deployment\check-sns-config.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "DEPLOYMENT ABORTED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "SNS configuration check failed." -ForegroundColor Red
    Write-Host "Please fix the issues above before deploying." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
Write-Host "  SNS configuration OK" -ForegroundColor Green
Write-Host ""

# Step 1: Build HTML (without API URL)
Write-Host "[1/7] Building HTML with SMS integration..." -ForegroundColor Green
python $BUILD_SCRIPT
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Build script failed" -ForegroundColor Red
    exit 1
}
Write-Host "  Build complete" -ForegroundColor Green
Write-Host ""

# Step 2: Deploy Lambda + API Gateway
Write-Host "[2/7] Deploying Lambda + API Gateway..." -ForegroundColor Green
Write-Host "  Using SAM CLI to deploy backend..." -ForegroundColor Yellow

# Check if SAM CLI is installed
$samInstalled = Get-Command sam -ErrorAction SilentlyContinue
if (-not $samInstalled) {
    Write-Host "ERROR: AWS SAM CLI not found. Please install it first:" -ForegroundColor Red
    Write-Host "  https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html" -ForegroundColor Yellow
    exit 1
}

# Deploy with SAM
Push-Location "Gemini3_AllSensesAI/backend/sms"
try {
    sam build --template-file template.yaml
    if ($LASTEXITCODE -ne 0) {
        throw "SAM build failed"
    }
    
    sam deploy `
        --stack-name $STACK_NAME `
        --parameter-overrides Environment=$ENVIRONMENT `
        --capabilities CAPABILITY_IAM `
        --no-confirm-changeset `
        --no-fail-on-empty-changeset
    
    if ($LASTEXITCODE -ne 0) {
        throw "SAM deploy failed"
    }
} finally {
    Pop-Location
}

Write-Host "  Lambda + API Gateway deployed" -ForegroundColor Green
Write-Host ""

# Step 3: Get API Gateway URL
Write-Host "[3/7] Retrieving API Gateway URL..." -ForegroundColor Green
$apiUrl = aws cloudformation describe-stacks `
    --stack-name $STACK_NAME `
    --query "Stacks[0].Outputs[?OutputKey=='SmsApiUrl'].OutputValue" `
    --output text

if (-not $apiUrl) {
    Write-Host "ERROR: Could not retrieve API URL from stack outputs" -ForegroundColor Red
    exit 1
}

Write-Host "  API URL: $apiUrl" -ForegroundColor Green
Write-Host ""

# Step 4: Update HTML with real API URL
Write-Host "[4/7] Updating HTML with API URL..." -ForegroundColor Green
$htmlContent = Get-Content $HTML_FILE -Raw -Encoding UTF8
$htmlContent = $htmlContent -replace 'https://YOUR_API_GATEWAY_URL_HERE/prod/send-sms', $apiUrl
Set-Content $HTML_FILE -Value $htmlContent -Encoding UTF8 -NoNewline
Write-Host "  HTML updated with API URL" -ForegroundColor Green
Write-Host ""

# Step 5: Upload to S3
Write-Host "[5/7] Uploading to S3..." -ForegroundColor Green
aws s3 cp $HTML_FILE "s3://$S3_BUCKET/index.html" `
    --content-type "text/html" `
    --cache-control "no-cache, no-store, must-revalidate"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: S3 upload failed" -ForegroundColor Red
    exit 1
}
Write-Host "  Uploaded to S3" -ForegroundColor Green
Write-Host ""

# Step 6: Create CloudFront invalidation
Write-Host "[6/7] Creating CloudFront invalidation..." -ForegroundColor Green
$invalidationId = aws cloudfront create-invalidation `
    --distribution-id $CLOUDFRONT_DIST_ID `
    --paths "/*" `
    --query "Invalidation.Id" `
    --output text

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: CloudFront invalidation failed" -ForegroundColor Red
    exit 1
}
Write-Host "  Invalidation ID: $invalidationId" -ForegroundColor Green
Write-Host ""

# Step 7: Wait for invalidation to complete
Write-Host "[7/7] Waiting for CloudFront invalidation..." -ForegroundColor Green
Write-Host "  This may take 1-3 minutes..." -ForegroundColor Yellow

$maxWaitSeconds = 180
$waitedSeconds = 0
$checkInterval = 10

while ($waitedSeconds -lt $maxWaitSeconds) {
    $status = aws cloudfront get-invalidation `
        --distribution-id $CLOUDFRONT_DIST_ID `
        --id $invalidationId `
        --query "Invalidation.Status" `
        --output text
    
    if ($status -eq "Completed") {
        Write-Host "  Invalidation completed!" -ForegroundColor Green
        break
    }
    
    Write-Host "  Status: $status (waited $waitedSeconds seconds)" -ForegroundColor Yellow
    Start-Sleep -Seconds $checkInterval
    $waitedSeconds += $checkInterval
}

if ($waitedSeconds -ge $maxWaitSeconds) {
    Write-Host "  Invalidation still in progress (timeout reached)" -ForegroundColor Yellow
    Write-Host "  You can check status manually with:" -ForegroundColor Yellow
    Write-Host "    aws cloudfront get-invalidation --distribution-id $CLOUDFRONT_DIST_ID --id $invalidationId" -ForegroundColor Cyan
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "SMS Backend:" -ForegroundColor Yellow
Write-Host "  Stack: $STACK_NAME"
Write-Host "  API URL: $apiUrl"
Write-Host ""
Write-Host "Frontend:" -ForegroundColor Yellow
Write-Host "  CloudFront URL: https://dfc8ght8abwqc.cloudfront.net"
Write-Host "  Build ID: GEMINI3-JURY-READY-VIDEO-SMS-20260128-v2"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Open: https://dfc8ght8abwqc.cloudfront.net"
Write-Host "  2. Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)"
Write-Host "  3. Complete Step 1 with Colombia number: +573222063010"
Write-Host "  4. Click 'Send Test SMS' to test delivery"
Write-Host "  5. Check phone for SMS arrival"
Write-Host ""
Write-Host "Verification:" -ForegroundColor Yellow
Write-Host "  - Check Build ID shows v2 in top stamp and Runtime Health Check"
Write-Host "  - Verify SMS Delivery Proof panel appears in Step 5"
Write-Host "  - Test SMS sending with real Colombia number"
Write-Host "  - Verify SMS content matches preview exactly"
Write-Host ""
Write-Host "CloudWatch Logs:" -ForegroundColor Yellow
Write-Host "  Lambda: aws logs tail /aws/lambda/gemini3-sms-sender-prod --follow"
Write-Host "  SNS: Check delivery logs in AWS Console after 1-2 minutes"
Write-Host ""
