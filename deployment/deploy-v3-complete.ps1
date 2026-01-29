#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete v3 Deployment - Colombia SMS + UI Fix
    
.DESCRIPTION
    Deploys GEMINI3-JURY-READY-VIDEO-SMS-20260128-v3 with:
    - SMS backend (Lambda + API Gateway)
    - Frontend with real API URL
    - CloudFront with cache-busting headers
    - Comprehensive invalidation
    
.NOTES
    Build ID: GEMINI3-JURY-READY-VIDEO-SMS-20260128-v3
    Addresses: SMS delivery + "Waiting for threat analysis..." stuck message
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Configuration
$BUILD_ID = "GEMINI3-JURY-READY-VIDEO-SMS-20260128-v3"
$BASELINE_HTML = "Gemini3_AllSensesAI/gemini3-guardian-jury-ready-video-sms.html"
$STACK_NAME = "gemini3-sms-backend"
$CF_STACK_NAME = "gemini3-jury-ready-cf"
$REGION = "us-east-1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "v3 Complete Deployment" -ForegroundColor Cyan
Write-Host "Build: $BUILD_ID" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# PART A: Verify Build ID in HTML
# ============================================================
Write-Host "[A] Verifying Build ID in HTML..." -ForegroundColor Yellow

if (-not (Test-Path $BASELINE_HTML)) {
    Write-Host "ERROR: HTML file not found: $BASELINE_HTML" -ForegroundColor Red
    Write-Host "Run: python Gemini3_AllSensesAI/create-colombia-sms-fix-v3.py" -ForegroundColor Yellow
    exit 1
}

$htmlContent = Get-Content $BASELINE_HTML -Raw

# Check Build ID in 2 locations
$buildIdCount = ([regex]::Matches($htmlContent, [regex]::Escape($BUILD_ID))).Count

if ($buildIdCount -lt 2) {
    Write-Host "ERROR: Build ID not found in HTML (expected 2+ occurrences, found $buildIdCount)" -ForegroundColor Red
    Write-Host "Run: python Gemini3_AllSensesAI/create-colombia-sms-fix-v3.py" -ForegroundColor Yellow
    exit 1
}

Write-Host "  Build ID verified in HTML ($buildIdCount occurrences)" -ForegroundColor Green

# Check for SMS functions
if ($htmlContent -notmatch "async function sendSms") {
    Write-Host "ERROR: SMS functions not found in HTML" -ForegroundColor Red
    exit 1
}

if ($htmlContent -notmatch "smsDeliveryProofPanel") {
    Write-Host "ERROR: Delivery Proof panel not found in HTML" -ForegroundColor Red
    exit 1
}

if ($htmlContent -notmatch "NO RISK GATING") {
    Write-Host "ERROR: No risk gating comment not found in HTML" -ForegroundColor Red
    exit 1
}

Write-Host "  SMS functions verified" -ForegroundColor Green
Write-Host ""

# ============================================================
# PART B: Check SNS Configuration
# ============================================================
Write-Host "[B] Checking SNS Configuration..." -ForegroundColor Yellow

try {
    $snsAttrs = aws sns get-sms-attributes --region $REGION | ConvertFrom-Json
    
    $spendLimit = $snsAttrs.attributes.'MonthlySpendLimit'
    if ($spendLimit -eq "0" -or $spendLimit -eq "0.00") {
        Write-Host "ERROR: SNS monthly spend limit is `$0" -ForegroundColor Red
        Write-Host "Fix: AWS Console -> SNS -> Text messaging (SMS) -> Preferences" -ForegroundColor Yellow
        Write-Host "Set 'Account spend limit' to `$5 or `$10" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "  SNS spend limit: `$$spendLimit" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Could not check SNS configuration" -ForegroundColor Yellow
    Write-Host "  $_" -ForegroundColor Gray
}

Write-Host ""

# ============================================================
# PART C: Deploy Backend (Lambda + API Gateway)
# ============================================================
Write-Host "[C] Deploying SMS Backend..." -ForegroundColor Yellow

$stackExists = $false
try {
    aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION | Out-Null
    $stackExists = $true
    Write-Host "  Stack exists: $STACK_NAME" -ForegroundColor Gray
} catch {
    Write-Host "  Stack does not exist, will create" -ForegroundColor Gray
}

if ($stackExists) {
    Write-Host "  Updating stack..." -ForegroundColor Gray
    sam deploy `
        --template-file Gemini3_AllSensesAI/backend/sms/template.yaml `
        --stack-name $STACK_NAME `
        --capabilities CAPABILITY_IAM `
        --region $REGION `
        --no-confirm-changeset `
        --no-fail-on-empty-changeset
} else {
    Write-Host "  Creating stack..." -ForegroundColor Gray
    sam deploy `
        --template-file Gemini3_AllSensesAI/backend/sms/template.yaml `
        --stack-name $STACK_NAME `
        --capabilities CAPABILITY_IAM `
        --region $REGION `
        --no-confirm-changeset
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Backend deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "  Backend deployed successfully" -ForegroundColor Green
Write-Host ""

# ============================================================
# PART D: Get API Gateway URL
# ============================================================
Write-Host "[D] Getting API Gateway URL..." -ForegroundColor Yellow

$outputs = aws cloudformation describe-stacks `
    --stack-name $STACK_NAME `
    --region $REGION `
    --query "Stacks[0].Outputs" | ConvertFrom-Json

$apiUrl = ($outputs | Where-Object { $_.OutputKey -eq "SmsApiUrl" }).OutputValue

if (-not $apiUrl) {
    Write-Host "ERROR: Could not get API Gateway URL from stack outputs" -ForegroundColor Red
    exit 1
}

Write-Host "  API URL: $apiUrl" -ForegroundColor Green
Write-Host ""

# ============================================================
# PART E: Update HTML with Real API URL
# ============================================================
Write-Host "[E] Updating HTML with real API URL..." -ForegroundColor Yellow

$updatedHtml = $htmlContent -replace "https://YOUR_API_GATEWAY_URL_HERE/prod/send-sms", $apiUrl

# Verify replacement worked
if ($updatedHtml -match "YOUR_API_GATEWAY_URL_HERE") {
    Write-Host "ERROR: API URL placeholder still present after replacement" -ForegroundColor Red
    exit 1
}

# Save updated HTML to temp file
$tempHtml = "Gemini3_AllSensesAI/gemini3-guardian-jury-ready-video-sms-deployed.html"
$updatedHtml | Out-File -FilePath $tempHtml -Encoding UTF8 -NoNewline

Write-Host "  HTML updated with real API URL" -ForegroundColor Green
Write-Host "  Saved to: $tempHtml" -ForegroundColor Gray
Write-Host ""

# ============================================================
# PART F: Get CloudFront Distribution Info
# ============================================================
Write-Host "[F] Getting CloudFront distribution info..." -ForegroundColor Yellow

$cfOutputs = aws cloudformation describe-stacks `
    --stack-name $CF_STACK_NAME `
    --region $REGION `
    --query "Stacks[0].Outputs" | ConvertFrom-Json

$distributionId = ($cfOutputs | Where-Object { $_.OutputKey -eq "DistributionId" }).OutputValue
$bucketName = ($cfOutputs | Where-Object { $_.OutputKey -eq "BucketName" }).OutputValue
$cloudfrontUrl = ($cfOutputs | Where-Object { $_.OutputKey -eq "CloudFrontURL" }).OutputValue

if (-not $distributionId -or -not $bucketName) {
    Write-Host "ERROR: Could not get CloudFront info from stack outputs" -ForegroundColor Red
    exit 1
}

Write-Host "  Distribution ID: $distributionId" -ForegroundColor Green
Write-Host "  Bucket: $bucketName" -ForegroundColor Green
Write-Host "  CloudFront URL: $cloudfrontUrl" -ForegroundColor Green
Write-Host ""

# ============================================================
# PART G: Upload HTML to S3 with Cache-Busting Headers
# ============================================================
Write-Host "[G] Uploading HTML to S3 with cache-busting headers..." -ForegroundColor Yellow

# Upload with aggressive cache-busting headers
aws s3 cp $tempHtml "s3://$bucketName/index.html" `
    --content-type "text/html; charset=utf-8" `
    --cache-control "no-store, no-cache, must-revalidate, max-age=0" `
    --metadata-directive REPLACE `
    --region $REGION

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: S3 upload failed" -ForegroundColor Red
    exit 1
}

Write-Host "  HTML uploaded to S3 with cache-busting headers" -ForegroundColor Green
Write-Host ""

# ============================================================
# PART H: Create CloudFront Invalidation
# ============================================================
Write-Host "[H] Creating CloudFront invalidation..." -ForegroundColor Yellow

$invalidationPaths = @("/index.html", "/*")
$invalidationPathsJson = $invalidationPaths | ConvertTo-Json -Compress

$callerRef = "v3-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

$invalidationResult = aws cloudfront create-invalidation `
    --distribution-id $distributionId `
    --paths $invalidationPathsJson `
    --caller-reference $callerRef `
    --region $REGION | ConvertFrom-Json

$invalidationId = $invalidationResult.Invalidation.Id

Write-Host "  Invalidation created: $invalidationId" -ForegroundColor Green
Write-Host "  Paths: $($invalidationPaths -join ', ')" -ForegroundColor Gray
Write-Host ""

# ============================================================
# PART I: Wait for Invalidation to Complete
# ============================================================
Write-Host "[I] Waiting for invalidation to complete..." -ForegroundColor Yellow
Write-Host "  This may take 1-3 minutes..." -ForegroundColor Gray

$maxWait = 300  # 5 minutes
$waited = 0
$checkInterval = 10

while ($waited -lt $maxWait) {
    Start-Sleep -Seconds $checkInterval
    $waited += $checkInterval
    
    $invalidationStatus = aws cloudfront get-invalidation `
        --distribution-id $distributionId `
        --id $invalidationId `
        --region $REGION | ConvertFrom-Json
    
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
# PART J: Verification
# ============================================================
Write-Host "[J] Verification..." -ForegroundColor Yellow

Write-Host "  CloudFront URL: $cloudfrontUrl" -ForegroundColor Cyan
Write-Host ""

Write-Host "CRITICAL: Open in INCOGNITO/PRIVATE window to bypass browser cache!" -ForegroundColor Yellow
Write-Host ""

Write-Host "Verify the following:" -ForegroundColor White
Write-Host "  1. Build ID shows: $BUILD_ID" -ForegroundColor White
Write-Host "     - Check top banner" -ForegroundColor Gray
Write-Host "     - Check Runtime Health Check panel" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. After Step 4 completes, Step 5 status:" -ForegroundColor White
Write-Host "     - Does NOT say 'Waiting for threat analysis...'" -ForegroundColor Gray
Write-Host "     - Says 'Threat analysis complete' or 'Ready to send alert'" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Manual SMS Test button visible after Step 1" -ForegroundColor White
Write-Host ""
Write-Host "  4. Clicking 'Send Test SMS':" -ForegroundColor White
Write-Host "     - Shows 'Sending...' status" -ForegroundColor Gray
Write-Host "     - Delivery Proof panel shows:" -ForegroundColor Gray
Write-Host "       * httpStatus=200" -ForegroundColor Gray
Write-Host "       * Real messageId" -ForegroundColor Gray
Write-Host "       * Masked destination (+57***3010)" -ForegroundColor Gray
Write-Host ""
Write-Host "  5. Colombia phone receives SMS" -ForegroundColor White
Write-Host ""

# ============================================================
# PART K: Test SMS (Optional)
# ============================================================
Write-Host "[K] Test SMS Backend (Optional)..." -ForegroundColor Yellow

$testSms = Read-Host "Send test SMS now? (y/N)"

if ($testSms -eq "y" -or $testSms -eq "Y") {
    $testPhone = Read-Host "Enter Colombia phone number (E.164 format, e.g., +573222063010)"
    
    if ($testPhone -match '^\+57\d{10}$') {
        Write-Host "  Sending test SMS to $testPhone..." -ForegroundColor Gray
        
        $testPayload = @{
            to = $testPhone
            message = "Test SMS from AllSensesAI Gemini3 Guardian. Build: $BUILD_ID. If you receive this, SMS delivery is working!"
            buildId = $BUILD_ID
            meta = @{
                victimName = "Test User"
                risk = "TEST"
                confidence = "100%"
                recommendation = "This is a test"
                triggerMessage = "Manual test"
                triggerType = "MANUAL"
                lat = 4.7110
                lng = -74.0721
                mapUrl = "https://www.google.com/maps?q=4.7110,-74.0721"
                timestampIso = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                action = "Test"
            }
        } | ConvertTo-Json -Depth 10
        
        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $testPayload -ContentType "application/json"
            
            if ($response.ok) {
                Write-Host "  SUCCESS: SMS sent!" -ForegroundColor Green
                Write-Host "  Message ID: $($response.messageId)" -ForegroundColor Green
                Write-Host "  Destination: $($response.toMasked)" -ForegroundColor Green
                Write-Host "  Check phone for delivery (5-30 seconds)" -ForegroundColor Yellow
            } else {
                Write-Host "  FAILED: $($response.errorMessage)" -ForegroundColor Red
                Write-Host "  Error Code: $($response.errorCode)" -ForegroundColor Red
            }
        } catch {
            Write-Host "  ERROR: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  Invalid phone number format. Must be E.164 (+573222063010)" -ForegroundColor Red
    }
}

Write-Host ""

# ============================================================
# Summary
# ============================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Build ID: $BUILD_ID" -ForegroundColor Green
Write-Host "CloudFront URL: $cloudfrontUrl" -ForegroundColor Green
Write-Host "API Gateway URL: $apiUrl" -ForegroundColor Green
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Open CloudFront URL in INCOGNITO window" -ForegroundColor White
Write-Host "2. Verify Build ID shows v3 (not v1)" -ForegroundColor White
Write-Host "3. Complete Steps 1-4" -ForegroundColor White
Write-Host "4. Verify Step 5 status does NOT say 'Waiting...'" -ForegroundColor White
Write-Host "5. Click 'Send Test SMS' and verify delivery" -ForegroundColor White
Write-Host ""
Write-Host "If Build ID still shows v1:" -ForegroundColor Yellow
Write-Host "- Clear browser cache completely" -ForegroundColor White
Write-Host "- Try different browser" -ForegroundColor White
Write-Host "- Wait 5 more minutes for CDN propagation" -ForegroundColor White
Write-Host ""
