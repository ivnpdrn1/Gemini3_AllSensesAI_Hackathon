# Deploy Production SMS Build to CloudFront
# AllSenses AI Guardian - Production SMS Restoration

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Production SMS Build Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$BUILD_FILE = "Gemini3_AllSensesAI/gemini3-guardian-production-sms.html"
$BUILD_ID = "GEMINI3-GUARDIAN-PRODUCTION-SMS-20260129-v1"

# TODO: Replace with your actual values
$S3_BUCKET = "YOUR_S3_BUCKET_NAME"
$CLOUDFRONT_DISTRIBUTION_ID = "YOUR_CLOUDFRONT_DISTRIBUTION_ID"
$CLOUDFRONT_URL = "YOUR_CLOUDFRONT_URL.cloudfront.net"

Write-Host "[1] Validating build file..." -ForegroundColor Yellow

if (-not (Test-Path $BUILD_FILE)) {
    Write-Host "ERROR: Build file not found: $BUILD_FILE" -ForegroundColor Red
    exit 1
}

$fileSize = (Get-Item $BUILD_FILE).Length
Write-Host "  Build File: $BUILD_FILE" -ForegroundColor Green
Write-Host "  Size: $fileSize bytes" -ForegroundColor Green
Write-Host ""

Write-Host "[2] Verifying build configuration..." -ForegroundColor Yellow

# Check for Function URL
$content = Get-Content $BUILD_FILE -Raw
if ($content -match "SMS_FUNCTION_URL = 'https://q4ouvfydgod6o734zbfipyi45q0lyuhx\.lambda-url\.us-east-1\.on\.aws/'") {
    Write-Host "  Function URL: Configured ✓" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Function URL may not be configured correctly" -ForegroundColor Yellow
}

# Check for JURY references
$juryCount = (Select-String -Path $BUILD_FILE -Pattern "JURY" -CaseSensitive | Measure-Object).Count
if ($juryCount -eq 0) {
    Write-Host "  JURY References: None ✓" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Found $juryCount JURY references" -ForegroundColor Yellow
}

# Check for Build ID
if ($content -match $BUILD_ID) {
    Write-Host "  Build ID: $BUILD_ID ✓" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Build ID not found" -ForegroundColor Yellow
}

Write-Host ""

# Check if S3 bucket and CloudFront are configured
if ($S3_BUCKET -eq "YOUR_S3_BUCKET_NAME") {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "CONFIGURATION REQUIRED" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please edit this script and replace:" -ForegroundColor Yellow
    Write-Host "  - S3_BUCKET with your actual S3 bucket name" -ForegroundColor White
    Write-Host "  - CLOUDFRONT_DISTRIBUTION_ID with your CloudFront distribution ID" -ForegroundColor White
    Write-Host "  - CLOUDFRONT_URL with your CloudFront URL" -ForegroundColor White
    Write-Host ""
    Write-Host "Then run this script again." -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

Write-Host "[3] Uploading to S3..." -ForegroundColor Yellow

aws s3 cp $BUILD_FILE `
    "s3://$S3_BUCKET/index.html" `
    --cache-control "max-age=0, no-cache, no-store, must-revalidate" `
    --content-type "text/html" `
    --region us-east-1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: S3 upload failed" -ForegroundColor Red
    exit 1
}

Write-Host "  Uploaded to: s3://$S3_BUCKET/index.html" -ForegroundColor Green
Write-Host ""

Write-Host "[4] Invalidating CloudFront cache..." -ForegroundColor Yellow

$invalidation = aws cloudfront create-invalidation `
    --distribution-id $CLOUDFRONT_DISTRIBUTION_ID `
    --paths "/*" `
    --query "Invalidation.Id" `
    --output text

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: CloudFront invalidation failed" -ForegroundColor Red
    exit 1
}

Write-Host "  Invalidation ID: $invalidation" -ForegroundColor Green
Write-Host "  Status: In Progress (takes 1-2 minutes)" -ForegroundColor Yellow
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "CloudFront URL:" -ForegroundColor Cyan
Write-Host "  https://$CLOUDFRONT_URL" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Wait 1-2 minutes for cache invalidation" -ForegroundColor White
Write-Host "  2. Open in INCOGNITO mode to avoid browser cache" -ForegroundColor White
Write-Host "  3. Verify Build ID: $BUILD_ID" -ForegroundColor White
Write-Host "  4. Test SMS with US number (+1)" -ForegroundColor White
Write-Host "  5. Test SMS with Colombia number (+57)" -ForegroundColor White
Write-Host ""
Write-Host "Verification Command:" -ForegroundColor Cyan
Write-Host "  start chrome --incognito https://$CLOUDFRONT_URL" -ForegroundColor White
Write-Host ""

