# Deploy Final Production Build
# Comprehensive build with all fixes merged
# Uses CORRECT deployment targets from existing environment

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Final Production Build Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# CORRECT Configuration (from existing deployment environment)
$BUCKET_NAME = "gemini-demo-20260127092219"
$CLOUDFRONT_ID = "E1YPPQKVA0OGX"
$SOURCE_FILE = "Gemini3_AllSensesAI/gemini3-guardian-final-production.html"
$S3_KEY = "index.html"

# Verify source file exists
if (-not (Test-Path $SOURCE_FILE)) {
    Write-Host "ERROR: Source file not found: $SOURCE_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "Source file: $SOURCE_FILE" -ForegroundColor Green
Write-Host "S3 Bucket: $BUCKET_NAME" -ForegroundColor Green
Write-Host "CloudFront: $CLOUDFRONT_ID" -ForegroundColor Green
Write-Host "CloudFront Domain: d3pbubsw4or36l.cloudfront.net" -ForegroundColor Green
Write-Host ""

# Step 1: Upload to S3
Write-Host "[1/3] Uploading to S3..." -ForegroundColor Yellow
aws s3 cp $SOURCE_FILE "s3://$BUCKET_NAME/$S3_KEY" `
    --content-type "text/html" `
    --cache-control "no-cache, no-store, must-revalidate" `
    --metadata "build=GEMINI3-FINAL-PRODUCTION-20260128,deployed=$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: S3 upload failed" -ForegroundColor Red
    exit 1
}

Write-Host "Success: Uploaded to S3" -ForegroundColor Green
Write-Host ""

# Step 2: Create CloudFront invalidation
Write-Host "[2/3] Creating CloudFront invalidation..." -ForegroundColor Yellow
$INVALIDATION_OUTPUT = aws cloudfront create-invalidation `
    --distribution-id $CLOUDFRONT_ID `
    --paths "/*" `
    --output json

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: CloudFront invalidation failed" -ForegroundColor Red
    exit 1
}

$INVALIDATION_ID = ($INVALIDATION_OUTPUT | ConvertFrom-Json).Invalidation.Id
Write-Host "Success: Invalidation created: $INVALIDATION_ID" -ForegroundColor Green
Write-Host ""

# Step 3: Verify deployment
Write-Host "[3/3] Verifying deployment..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Production URL: https://d3pbubsw4or36l.cloudfront.net" -ForegroundColor Cyan
Write-Host ""
Write-Host "Invalidation status:" -ForegroundColor Yellow
aws cloudfront get-invalidation `
    --distribution-id $CLOUDFRONT_ID `
    --id $INVALIDATION_ID `
    --query "Invalidation.Status" `
    --output text

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Build: GEMINI3-FINAL-PRODUCTION-20260128" -ForegroundColor Cyan
Write-Host ""
Write-Host "Fixes included:" -ForegroundColor Cyan
Write-Host "  Step 1: Button click fix (working)" -ForegroundColor White
Write-Host "  Step 5: Always-visible structured fields" -ForegroundColor White
Write-Host "  Step 5: Victim name in preview + sent SMS" -ForegroundColor White
Write-Host "  All existing features preserved" -ForegroundColor White
Write-Host ""
Write-Host "Test the deployment:" -ForegroundColor Yellow
Write-Host "1. Open: https://d3pbubsw4or36l.cloudfront.net" -ForegroundColor White
Write-Host "2. Hard refresh (Ctrl+Shift+R)" -ForegroundColor White
Write-Host "3. Verify build stamp: GEMINI3-FINAL-PRODUCTION-20260128" -ForegroundColor White
Write-Host "4. Complete Step 1 (name + phone)" -ForegroundColor White
Write-Host "5. Complete Step 2 (location)" -ForegroundColor White
Write-Host "6. Check Step 5 SMS preview (should show structured fields)" -ForegroundColor White
Write-Host "7. Complete Steps 3-4 to trigger emergency" -ForegroundColor White
Write-Host "8. Verify SMS shows 'Victim: <name>'" -ForegroundColor White
Write-Host ""
Write-Host "Wait 20-60 seconds for CloudFront cache to clear" -ForegroundColor Yellow
Write-Host ""
