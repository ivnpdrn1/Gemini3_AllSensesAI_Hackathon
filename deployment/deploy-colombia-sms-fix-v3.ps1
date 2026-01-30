#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Colombia SMS Fix v3 Deployment
    
.DESCRIPTION
    Deploys GEMINI3-COLOMBIA-SMS-FIX-20260129-v3 with:
    - Fixed SMS backend (Lambda with v4 handler)
    - Fixed frontend (checks data.ok && data.messageId)
    - CloudFront with aggressive cache-busting
    - Build ID v3 (not v1)
    
.NOTES
    Build ID: GEMINI3-COLOMBIA-SMS-FIX-20260129-v3
    Fixes:
    - Backend returns HTTP 200 ONLY when ok:true AND messageId exists
    - Frontend checks data.ok && data.messageId (not HTTP status text)
    - Step 5 status never stuck on "Waiting for threat analysis..."
    - CloudFront serves v3 (not v1)
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Configuration
$BUILD_ID = "GEMINI3-COLOMBIA-SMS-FIX-20260129-v3"
$FRONTEND_HTML = "Gemini3_AllSensesAI/deployment/ui/index.html"
$BACKEND_HANDLER = "Gemini3_AllSensesAI/backend/sms/lambda_function_url_handler_v4.py"
$REGION = "us-east-1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Colombia SMS Fix v3 Deployment" -ForegroundColor Cyan
Write-Host "Build: $BUILD_ID" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# PART A: Verify Build ID in Frontend
# ============================================================
Write-Host "[A] Verifying Build ID in frontend..." -ForegroundColor Yellow

if (-not (Test-Path $FRONTEND_HTML)) {
    Write-Host "ERROR: Frontend HTML not found: $FRONTEND_HTML" -ForegroundColor Red
    exit 1
}

$htmlContent = Get-Content $FRONTEND_HTML -Raw

# Check Build ID in 3 locations (header, health panel, JS constant)
$buildIdCount = ([regex]::Matches($htmlContent, [regex]::Escape($BUILD_ID))).Count

if ($buildIdCount -lt 3) {
    Write-Host "ERROR: Build ID not found in HTML (expected 3+ occurrences, found $buildIdCount)" -ForegroundColor Red
    Write-Host "Expected: $BUILD_ID" -ForegroundColor Yellow
    exit 1
}

Write-Host "  Build ID verified in HTML ($buildIdCount occurrences)" -ForegroundColor Green

# Verify frontend fixes
if ($htmlContent -notmatch "result\.ok === true && result\.messageId") {
    Write-Host "ERROR: Frontend fix not found (data.ok && data.messageId check)" -ForegroundColor Red
    exit 1
}

Write-Host "  Frontend SMS fix verified" -ForegroundColor Green
Write-Host ""

# ============================================================
# PART B: Verify Backend Handler
# ============================================================
Write-Host "[B] Verifying backend handler..." -ForegroundColor Yellow

if (-not (Test-Path $BACKEND_HANDLER)) {
    Write-Host "ERROR: Backend handler not found: $BACKEND_HANDLER" -ForegroundColor Red
    exit 1
}

$handlerContent = Get-Content $BACKEND_HANDLER -Raw

# Verify v4 API contract
if ($handlerContent -notmatch "Backend returns HTTP 200 only when SNS publish succeeds with MessageId") {
    Write-Host "ERROR: Backend v4 contract not found" -ForegroundColor Red
    exit 1
}

if ($handlerContent -notmatch "Validate E\.164 format") {
    Write-Host "ERROR: E.164 validation not found in backend" -ForegroundColor Red
    exit 1
}

Write-Host "  Backend v4 handler verified" -ForegroundColor Green
Write-Host ""

# ============================================================
# PART C: Check SNS Configuration
# ============================================================
Write-Host "[C] Checking SNS configuration..." -ForegroundColor Yellow

try {
    $snsAttrs = aws sns get-sms-attributes --region $REGION | ConvertFrom-Json
    
    $spendLimit = $snsAttrs.attributes.'MonthlySpendLimit'
    if ($spendLimit -eq "0" -or $spendLimit -eq "0.00") {
        Write-Host "ERROR: SNS monthly spend limit is `$0" -ForegroundColor Red
        Write-Host "Fix: AWS Console -> SNS -> Text messaging (SMS) -> Preferences" -ForegroundColor Yellow
        Write-Host "Set 'Account spend limit' to `$5 or `$10" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "  SNS spend limit: `$spendLimit" -ForegroundColor Green
    
    $defaultSmsType = $snsAttrs.attributes.'DefaultSMSType'
    Write-Host "  Default SMS type: $defaultSmsType" -ForegroundColor Gray
    
} catch {
    Write-Host "WARNING: Could not check SNS configuration" -ForegroundColor Yellow
    Write-Host "  $_" -ForegroundColor Gray
}

Write-Host ""

# ============================================================
# PART D: Deploy Backend Lambda
# ============================================================
Write-Host "[D] Deploying backend Lambda..." -ForegroundColor Yellow

# Get Lambda function name from CloudFormation or use default
$LAMBDA_FUNCTION_NAME = "allsenses-sms-production"

# Check if Lambda exists
$lambdaExists = $false
try {
    aws lambda get-function --function-name $LAMBDA_FUNCTION_NAME --region $REGION | Out-Null
    $lambdaExists = $true
    Write-Host "  Lambda function exists: $LAMBDA_FUNCTION_NAME" -ForegroundColor Gray
} catch {
    Write-Host "  Lambda function does not exist, will create" -ForegroundColor Gray
}

# Create deployment package
Write-Host "  Creating deployment package..." -ForegroundColor Gray
$tempDir = "Gemini3_AllSensesAI/backend/sms/package"
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Copy handler to package directory
Copy-Item -Path $BACKEND_HANDLER -Destination "$tempDir/lambda_function.py"

# Create ZIP
$zipPath = "Gemini3_AllSensesAI/backend/sms/lambda-v4.zip"
if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}

Compress-Archive -Path "$tempDir/*" -DestinationPath $zipPath -Force

Write-Host "  Deployment package created: $zipPath" -ForegroundColor Gray

# Update Lambda function code
if ($lambdaExists) {
    Write-Host "  Updating Lambda function code..." -ForegroundColor Gray
    aws lambda update-function-code `
        --function-name $LAMBDA_FUNCTION_NAME `
        --zip-file "fileb://$zipPath" `
        --region $REGION | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Lambda update failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  Lambda function updated" -ForegroundColor Green
} else {
    Write-Host "ERROR: Lambda function does not exist. Please create it first using SAM or CloudFormation." -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================================
# PART E: Get Lambda Function URL
# ============================================================
Write-Host "[E] Getting Lambda Function URL..." -ForegroundColor Yellow

$lambdaUrlConfig = aws lambda get-function-url-config `
    --function-name $LAMBDA_FUNCTION_NAME `
    --region $REGION | ConvertFrom-Json

$lambdaUrl = $lambdaUrlConfig.FunctionUrl

if (-not $lambdaUrl) {
    Write-Host "ERROR: Could not get Lambda Function URL" -ForegroundColor Red
    Write-Host "Make sure Lambda has a Function URL configured" -ForegroundColor Yellow
    exit 1
}

Write-Host "  Lambda URL: $lambdaUrl" -ForegroundColor Green
Write-Host ""

# ============================================================
# PART F: Get CloudFront Distribution Info
# ============================================================
Write-Host "[F] Getting CloudFront distribution info..." -ForegroundColor Yellow

# Try to get CloudFront info from CloudFormation
$CF_STACK_NAME = "gemini3-jury-ready-cf"

try {
    $cfOutputs = aws cloudformation describe-stacks `
        --stack-name $CF_STACK_NAME `
        --region $REGION `
        --query "Stacks[0].Outputs" | ConvertFrom-Json

    $distributionId = ($cfOutputs | Where-Object { $_.OutputKey -eq "DistributionId" }).OutputValue
    $bucketName = ($cfOutputs | Where-Object { $_.OutputKey -eq "BucketName" }).OutputValue
    $cloudfrontUrl = ($cfOutputs | Where-Object { $_.OutputKey -eq "CloudFrontURL" }).OutputValue

    if (-not $distributionId -or -not $bucketName) {
        throw "CloudFront info not found in stack outputs"
    }

    Write-Host "  Distribution ID: $distributionId" -ForegroundColor Green
    Write-Host "  Bucket: $bucketName" -ForegroundColor Green
    Write-Host "  CloudFront URL: $cloudfrontUrl" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Could not get CloudFront info from stack: $CF_STACK_NAME" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Please provide CloudFront details manually:" -ForegroundColor Yellow
    $distributionId = Read-Host "Distribution ID"
    $bucketName = Read-Host "S3 Bucket Name"
    $cloudfrontUrl = Read-Host "CloudFront URL"
}

Write-Host ""

# ============================================================
# PART G: Upload HTML to S3 with Aggressive Cache-Busting
# ============================================================
Write-Host "[G] Uploading HTML to S3 with cache-busting headers..." -ForegroundColor Yellow

# Upload with aggressive cache-busting headers
aws s3 cp $FRONTEND_HTML "s3://$bucketName/index.html" `
    --content-type "text/html; charset=utf-8" `
    --cache-control "max-age=0, no-cache, no-store, must-revalidate" `
    --metadata-directive REPLACE `
    --region $REGION

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: S3 upload failed" -ForegroundColor Red
    exit 1
}

Write-Host "  HTML uploaded to S3 with cache-busting headers" -ForegroundColor Green
Write-Host "  Cache-Control: max-age=0, no-cache, no-store, must-revalidate" -ForegroundColor Gray
Write-Host ""

# ============================================================
# PART H: Create CloudFront Invalidation
# ============================================================
Write-Host "[H] Creating CloudFront invalidation..." -ForegroundColor Yellow

$callerRef = "colombia-sms-fix-v3-$(Get-Date -Format 'yyyyMMddHHmmss')"

$invalidationJson = @{
    Paths = @{
        Quantity = 2
        Items = @("/*", "/index.html")
    }
    CallerReference = $callerRef
} | ConvertTo-Json -Depth 10

$invalidationResult = aws cloudfront create-invalidation `
    --distribution-id $distributionId `
    --invalidation-batch $invalidationJson | ConvertFrom-Json

$invalidationId = $invalidationResult.Invalidation.Id

Write-Host "  Invalidation created: $invalidationId" -ForegroundColor Green
Write-Host "  Paths: /* /index.html" -ForegroundColor Gray
Write-Host ""

# ============================================================
# PART I: Wait for Invalidation
# ============================================================
Write-Host "[I] Waiting for invalidation to complete..." -ForegroundColor Yellow
Write-Host "  This may take 1-3 minutes..." -ForegroundColor Gray

$maxWait = 180  # 3 minutes
$waited = 0
$checkInterval = 10

while ($waited -lt $maxWait) {
    Start-Sleep -Seconds $checkInterval
    $waited += $checkInterval
    
    $invalidationStatus = aws cloudfront get-invalidation `
        --distribution-id $distributionId `
        --id $invalidationId | ConvertFrom-Json
    
    $status = $invalidationStatus.Invalidation.Status
    
    Write-Host "  Status: $status (waited $waited seconds)" -ForegroundColor Gray
    
    if ($status -eq "Completed") {
        Write-Host "  Invalidation complete!" -ForegroundColor Green
        break
    }
}

if ($waited -ge $maxWait) {
    Write-Host "WARNING: Invalidation did not complete within $maxWait seconds" -ForegroundColor Yellow
    Write-Host "  It may still be in progress. Check AWS Console." -ForegroundColor Yellow
}

Write-Host ""

# ============================================================
# PART J: Verification Instructions
# ============================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Build ID: $BUILD_ID" -ForegroundColor Green
Write-Host "CloudFront URL: $cloudfrontUrl" -ForegroundColor Green
Write-Host "Lambda URL: $lambdaUrl" -ForegroundColor Green
Write-Host ""
Write-Host "CRITICAL: Open in INCOGNITO/PRIVATE window!" -ForegroundColor Yellow
Write-Host ""
Write-Host "ACCEPTANCE CRITERIA (All must pass):" -ForegroundColor White
Write-Host ""
Write-Host "1. CloudFront shows Build ID v3 (not v1)" -ForegroundColor White
Write-Host "   - Check top banner" -ForegroundColor Gray
Write-Host "   - Check Runtime Health Check panel" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Step 5 never stuck on 'Waiting for threat analysis...'" -ForegroundColor White
Write-Host "   - Complete Steps 1-4" -ForegroundColor Gray
Write-Host "   - After Step 4 completes, Step 5 status should update" -ForegroundColor Gray
Write-Host "   - Should say 'Ready to send alert' or similar" -ForegroundColor Gray
Write-Host ""
Write-Host "3. If SNS fails -> UI shows FAILED and backend returns non-200" -ForegroundColor White
Write-Host ""
Write-Host "4. If backend returns HTTP 200 -> includes ok:true and real messageId" -ForegroundColor White
Write-Host "   - Delivery Proof panel shows:" -ForegroundColor Gray
Write-Host "     * Status: SENT" -ForegroundColor Gray
Write-Host "     * HTTP Status: 200" -ForegroundColor Gray
Write-Host "     * SNS Message ID: (real UUID)" -ForegroundColor Gray
Write-Host "     * Destination: +57******3010" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Colombia SMS test shows 'SENT' with MessageId" -ForegroundColor White
Write-Host "   - Use Step 1 number +573222063010" -ForegroundColor Gray
Write-Host "   - Click 'Send Test SMS'" -ForegroundColor Gray
Write-Host "   - Delivery Proof shows SENT + MessageId" -ForegroundColor Gray
Write-Host ""
Write-Host "6. SMS actually arrives on Colombia phone (+57...)" -ForegroundColor White
Write-Host "   - Allow up to 30 seconds for carrier latency" -ForegroundColor Gray
Write-Host ""
Write-Host "If Build ID still shows v1:" -ForegroundColor Yellow
Write-Host "- Clear browser cache completely (Ctrl+Shift+Delete)" -ForegroundColor White
Write-Host "- Try different browser" -ForegroundColor White
Write-Host "- Wait 5 more minutes for CDN propagation" -ForegroundColor White
Write-Host "- Check S3 object metadata (should have cache-control headers)" -ForegroundColor White
Write-Host ""

