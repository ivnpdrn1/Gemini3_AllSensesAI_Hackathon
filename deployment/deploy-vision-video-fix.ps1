# Deploy Vision/Video Fix to CloudFront
# Build: GEMINI3-VISION-VIDEO-FIX-20260127

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Vision/Video Fix Deployment" -ForegroundColor Cyan
Write-Host "Build: GEMINI3-VISION-VIDEO-FIX-20260127" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$S3_BUCKET = "gemini-demo-20260127092219"
$CLOUDFRONT_DISTRIBUTION_ID = "E1YPPQKVA0OGX"
$UI_FILE = "Gemini3_AllSensesAI/deployment/ui/index.html"
$DEPLOYMENT_REGION = "us-east-1"

Write-Host "[1/5] Validating deployment file..." -ForegroundColor Yellow
if (-not (Test-Path $UI_FILE)) {
    Write-Host "ERROR: $UI_FILE not found!" -ForegroundColor Red
    exit 1
}

# Check for Vision panel in file
$content = Get-Content $UI_FILE -Raw
if ($content -notmatch "vision-context-panel") {
    Write-Host "ERROR: Vision panel not found in $UI_FILE!" -ForegroundColor Red
    exit 1
}

if ($content -notmatch "Video Frames \(Standby\)") {
    Write-Host "ERROR: Video Frames placeholder not found in $UI_FILE!" -ForegroundColor Red
    exit 1
}

Write-Host "  Vision panel detected in file" -ForegroundColor Green
Write-Host "  Video Frames placeholder detected" -ForegroundColor Green
Write-Host ""

Write-Host "[2/5] Uploading to S3..." -ForegroundColor Yellow
aws s3 cp $UI_FILE "s3://$S3_BUCKET/index.html" `
    --region $DEPLOYMENT_REGION `
    --content-type "text/html" `
    --cache-control "no-cache, no-store, must-revalidate" `
    --metadata "build=GEMINI3-VISION-VIDEO-FIX-20260127"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: S3 upload failed!" -ForegroundColor Red
    exit 1
}

Write-Host "  Uploaded to s3://$S3_BUCKET/index.html" -ForegroundColor Green
Write-Host ""

Write-Host "[3/5] Creating CloudFront invalidation..." -ForegroundColor Yellow
$invalidation = aws cloudfront create-invalidation `
    --distribution-id $CLOUDFRONT_DISTRIBUTION_ID `
    --paths "/index.html" "/" `
    --region $DEPLOYMENT_REGION `
    --output json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: CloudFront invalidation failed!" -ForegroundColor Red
    exit 1
}

$invalidationId = $invalidation.Invalidation.Id
Write-Host "  Invalidation created: $invalidationId" -ForegroundColor Green
Write-Host ""

Write-Host "[4/5] Waiting for invalidation to complete..." -ForegroundColor Yellow
Write-Host "  This may take 1-3 minutes..." -ForegroundColor Gray

$maxWaitSeconds = 180
$waitedSeconds = 0
$checkInterval = 10

while ($waitedSeconds -lt $maxWaitSeconds) {
    Start-Sleep -Seconds $checkInterval
    $waitedSeconds += $checkInterval
    
    $status = aws cloudfront get-invalidation `
        --distribution-id $CLOUDFRONT_DISTRIBUTION_ID `
        --id $invalidationId `
        --region $DEPLOYMENT_REGION `
        --output json | ConvertFrom-Json
    
    $currentStatus = $status.Invalidation.Status
    Write-Host "  Status: $currentStatus (waited ${waitedSeconds}s)" -ForegroundColor Gray
    
    if ($currentStatus -eq "Completed") {
        Write-Host "  Invalidation complete!" -ForegroundColor Green
        break
    }
}

if ($waitedSeconds -ge $maxWaitSeconds) {
    Write-Host "  WARNING: Invalidation still in progress after ${maxWaitSeconds}s" -ForegroundColor Yellow
    Write-Host "  Continuing anyway - changes will propagate shortly" -ForegroundColor Yellow
}

Write-Host ""

Write-Host "[5/5] Deployment Summary" -ForegroundColor Yellow
Write-Host "  Build: GEMINI3-VISION-VIDEO-FIX-20260127" -ForegroundColor White
Write-Host "  S3 Bucket: $S3_BUCKET" -ForegroundColor White
Write-Host "  CloudFront Distribution: $CLOUDFRONT_DISTRIBUTION_ID" -ForegroundColor White
Write-Host "  Invalidation ID: $invalidationId" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Open CloudFront URL in browser" -ForegroundColor White
Write-Host "2. Navigate to Step 4" -ForegroundColor White
Write-Host "3. Verify Vision panel is visible with Video Frames placeholders" -ForegroundColor White
Write-Host "4. Click 'Analyze with Gemini' to test activation" -ForegroundColor White
Write-Host "5. Verify state transitions: Standby -> Capturing -> Analyzing -> Complete" -ForegroundColor White
Write-Host ""

Write-Host "Verification Checklist:" -ForegroundColor Cyan
Write-Host "  [ ] Vision panel visible in Step 4" -ForegroundColor White
Write-Host "  [ ] 'Video Frames (Standby)' section visible" -ForegroundColor White
Write-Host "  [ ] 3 grey placeholder boxes visible" -ForegroundColor White
Write-Host "  [ ] Standby badge and explainer text visible" -ForegroundColor White
Write-Host "  [ ] After analysis: thumbnails, findings, confidence visible" -ForegroundColor White
Write-Host "  [ ] 'Added to Evidence Packet' indicator visible" -ForegroundColor White
Write-Host ""
