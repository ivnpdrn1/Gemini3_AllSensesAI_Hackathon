# Deploy Victim Name Enhanced Version
# Deploys the enhanced victim name display to CloudFront

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Victim Name Enhanced Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$BUCKET_NAME = "allsenses-gemini3-guardian"
$CLOUDFRONT_ID = "E1PQDO6YJHOV0H"
$SOURCE_FILE = "Gemini3_AllSensesAI/gemini3-guardian-victim-name-enhanced.html"
$S3_KEY = "index.html"

# Verify source file exists
if (-not (Test-Path $SOURCE_FILE)) {
    Write-Host "ERROR: Source file not found: $SOURCE_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "Source file: $SOURCE_FILE" -ForegroundColor Green
Write-Host "S3 Bucket: $BUCKET_NAME" -ForegroundColor Green
Write-Host "CloudFront: $CLOUDFRONT_ID" -ForegroundColor Green
Write-Host ""

# Step 1: Upload to S3
Write-Host "[1/3] Uploading to S3..." -ForegroundColor Yellow
aws s3 cp $SOURCE_FILE "s3://$BUCKET_NAME/$S3_KEY" `
    --content-type "text/html" `
    --cache-control "no-cache, no-store, must-revalidate" `
    --metadata "build=GEMINI3-VICTIM-NAME-ENHANCED-20260128,deployed=$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: S3 upload failed" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Uploaded to S3" -ForegroundColor Green
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
Write-Host "✓ Invalidation created: $INVALIDATION_ID" -ForegroundColor Green
Write-Host ""

# Step 3: Verify deployment
Write-Host "[3/3] Verifying deployment..." -ForegroundColor Yellow
Write-Host ""
Write-Host "CloudFront URL: https://d2s72i2kvhwvvl.cloudfront.net/" -ForegroundColor Cyan
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
Write-Host "Changes deployed:" -ForegroundColor Cyan
Write-Host "  • Changed 'Contact:' to 'Victim:' in SMS messages" -ForegroundColor White
Write-Host "  • Added 'Victim Name:' line item in Step 5 preview" -ForegroundColor White
Write-Host "  • Added fallback to 'Unknown User' if name empty" -ForegroundColor White
Write-Host "  • Added proof logging for victim name" -ForegroundColor White
Write-Host "  • Added warning display if using fallback" -ForegroundColor White
Write-Host ""
Write-Host "Test the deployment:" -ForegroundColor Yellow
Write-Host "1. Open: https://d2s72i2kvhwvvl.cloudfront.net/" -ForegroundColor White
Write-Host "2. Complete Step 1 with a name" -ForegroundColor White
Write-Host "3. Check Step 1 proof logs for victim name confirmation" -ForegroundColor White
Write-Host "4. Complete Steps 2-4 to trigger threat analysis" -ForegroundColor White
Write-Host "5. Check Step 5 SMS preview for 'Victim Name:' line" -ForegroundColor White
Write-Host "6. Verify SMS message shows 'Victim: <name>'" -ForegroundColor White
Write-Host ""
Write-Host "Wait 2-3 minutes for CloudFront cache to clear" -ForegroundColor Yellow
Write-Host ""
