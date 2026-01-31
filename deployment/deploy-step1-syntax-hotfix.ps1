# STEP 1 SYNTAX HOTFIX DEPLOYMENT
# Fixes: function updateMicStatus missing parameters
# Build: GEMINI3-GUARDIAN-SMS-VIDEO-20260131-v3-HOTFIX

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STEP 1 SYNTAX HOTFIX DEPLOYMENT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$SOURCE_FILE = "Gemini3_AllSensesAI/index.html"
$S3_BUCKET = "allsenses-gemini3-guardian"
$CLOUDFRONT_DIST_ID = "E1YJBHXMPFVWQO"
$BUILD_ID = "GEMINI3-GUARDIAN-SMS-VIDEO-20260131-v3-HOTFIX"

Write-Host "[1/4] Verifying source file..." -ForegroundColor Yellow
if (-not (Test-Path $SOURCE_FILE)) {
    Write-Host "ERROR: Source file not found: $SOURCE_FILE" -ForegroundColor Red
    exit 1
}
Write-Host "  Source file verified: $SOURCE_FILE" -ForegroundColor Green

Write-Host ""
Write-Host "[2/4] Uploading to S3 with cache-busting headers..." -ForegroundColor Yellow
aws s3 cp $SOURCE_FILE "s3://$S3_BUCKET/index.html" `
    --content-type "text/html; charset=utf-8" `
    --cache-control "max-age=0, no-cache, no-store, must-revalidate" `
    --metadata-directive REPLACE

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: S3 upload failed" -ForegroundColor Red
    exit 1
}
Write-Host "  Upload complete" -ForegroundColor Green

Write-Host ""
Write-Host "[3/4] Creating CloudFront invalidation..." -ForegroundColor Yellow
$invalidation = aws cloudfront create-invalidation `
    --distribution-id $CLOUDFRONT_DIST_ID `
    --paths "/index.html" `
    --output json | ConvertFrom-Json

$invalidationId = $invalidation.Invalidation.Id
Write-Host "  Invalidation created: $invalidationId" -ForegroundColor Green

Write-Host ""
Write-Host "[4/4] Waiting for invalidation to complete..." -ForegroundColor Yellow
aws cloudfront wait invalidation-completed `
    --distribution-id $CLOUDFRONT_DIST_ID `
    --id $invalidationId

Write-Host "  Invalidation complete" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Build ID: $BUILD_ID" -ForegroundColor Cyan
Write-Host "CloudFront URL: https://d3ux8qqvpqq5fy.cloudfront.net/" -ForegroundColor Cyan
Write-Host ""
Write-Host "VERIFICATION STEPS:" -ForegroundColor Yellow
Write-Host "1. Open browser console (F12)" -ForegroundColor White
Write-Host "2. Navigate to CloudFront URL" -ForegroundColor White
Write-Host "3. Verify console shows: [BOOT] JS loaded; completeStep1 type = function" -ForegroundColor White
Write-Host "4. Verify no SyntaxError on page load" -ForegroundColor White
Write-Host "5. Click 'Complete Step 1' button and verify it works" -ForegroundColor White
Write-Host ""
