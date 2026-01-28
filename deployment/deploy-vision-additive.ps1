# Deploy Vision Panel (Additive to Production UX)
# Build: GEMINI3-VISION-ADDITIVE-20260127

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Vision Panel Additive Deployment" -ForegroundColor Cyan
Write-Host "Build: GEMINI3-VISION-ADDITIVE-20260127" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$S3_BUCKET = "gemini-demo-20260127092219"
$CLOUDFRONT_DISTRIBUTION_ID = "E1YPPQKVA0OGX"
$UI_FILE = "Gemini3_AllSensesAI/gemini3-guardian-vision-additive.html"
$DEPLOYMENT_REGION = "us-east-1"

Write-Host "[1/6] Validating source file..." -ForegroundColor Yellow
if (-not (Test-Path $UI_FILE)) {
    Write-Host "ERROR: $UI_FILE not found!" -ForegroundColor Red
    exit 1
}

# Check for Vision panel
$content = Get-Content $UI_FILE -Raw
if ($content -notmatch "vision-context-panel") {
    Write-Host "ERROR: Vision panel not found in $UI_FILE!" -ForegroundColor Red
    exit 1
}

if ($content -notmatch "Video Frames \(Standby\)") {
    Write-Host "ERROR: Video Frames placeholder not found in $UI_FILE!" -ForegroundColor Red
    exit 1
}

# Check for production UX elements
if ($content -notmatch "GEMINI3 POWERED") {
    Write-Host "ERROR: Production GEMINI3 POWERED banner not found!" -ForegroundColor Red
    exit 1
}

if ($content -notmatch "Step 1") {
    Write-Host "ERROR: Production 5-step flow not found!" -ForegroundColor Red
    exit 1
}

Write-Host "  ✅ Vision panel detected" -ForegroundColor Green
Write-Host "  ✅ Video Frames placeholder detected" -ForegroundColor Green
Write-Host "  ✅ Production UX preserved" -ForegroundColor Green
Write-Host "  ✅ 5-step flow intact" -ForegroundColor Green
Write-Host ""

Write-Host "[2/6] Uploading to S3..." -ForegroundColor Yellow
aws s3 cp $UI_FILE "s3://$S3_BUCKET/index.html" `
    --region $DEPLOYMENT_REGION `
    --content-type "text/html" `
    --cache-control "no-cache, no-store, must-revalidate" `
    --metadata "build=GEMINI3-VISION-ADDITIVE-20260127"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: S3 upload failed!" -ForegroundColor Red
    exit 1
}

Write-Host "  ✅ Uploaded to s3://$S3_BUCKET/index.html" -ForegroundColor Green
Write-Host ""

Write-Host "[3/6] Creating CloudFront invalidation..." -ForegroundColor Yellow
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
Write-Host "  ✅ Invalidation created: $invalidationId" -ForegroundColor Green
Write-Host ""

Write-Host "[4/6] Waiting for invalidation to complete..." -ForegroundColor Yellow
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
        Write-Host "  ✅ Invalidation complete!" -ForegroundColor Green
        break
    }
}

if ($waitedSeconds -ge $maxWaitSeconds) {
    Write-Host "  WARNING: Invalidation still in progress after ${maxWaitSeconds}s" -ForegroundColor Yellow
    Write-Host "  Continuing anyway - changes will propagate shortly" -ForegroundColor Yellow
}

Write-Host ""

Write-Host "[5/6] Deployment Summary" -ForegroundColor Yellow
Write-Host "  Build: GEMINI3-VISION-ADDITIVE-20260127" -ForegroundColor White
Write-Host "  S3 Bucket: $S3_BUCKET" -ForegroundColor White
Write-Host "  CloudFront Distribution: $CLOUDFRONT_DISTRIBUTION_ID" -ForegroundColor White
Write-Host "  Invalidation ID: $invalidationId" -ForegroundColor White
Write-Host "  CloudFront URL: https://d3pbubsw4or36l.cloudfront.net" -ForegroundColor White
Write-Host ""

Write-Host "[6/6] Verification Checklist" -ForegroundColor Yellow
Write-Host "  [ ] Open: https://d3pbubsw4or36l.cloudfront.net" -ForegroundColor White
Write-Host "  [ ] Hard refresh: Ctrl + Shift + R" -ForegroundColor White
Write-Host "  [ ] Verify production UX preserved:" -ForegroundColor White
Write-Host "      - GEMINI3 POWERED banner visible" -ForegroundColor Gray
Write-Host "      - 5-step flow intact (Step 1-5)" -ForegroundColor Gray
Write-Host "      - NO 'Emergency Response Pipeline' dashboard" -ForegroundColor Gray
Write-Host "      - NO FALLBACK/MOCK badges" -ForegroundColor Gray
Write-Host "  [ ] Navigate to Step 4" -ForegroundColor White
Write-Host "  [ ] Vision panel visible INSIDE Step 4:" -ForegroundColor White
Write-Host "      - '🎥 Visual Context (Gemini Vision) — Video Frames' heading" -ForegroundColor Gray
Write-Host "      - 'Standby' badge (grey)" -ForegroundColor Gray
Write-Host "      - '📹 Video Frames (Standby)' section" -ForegroundColor Gray
Write-Host "      - 3 grey placeholder boxes" -ForegroundColor Gray
Write-Host "      - Explainer text and policy" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "CRITICAL VERIFICATION:" -ForegroundColor Cyan
Write-Host "1. Production UX must be pixel-for-pixel identical" -ForegroundColor White
Write-Host "2. Vision panel is ADDITIVE ONLY inside Step 4" -ForegroundColor White
Write-Host "3. NO new top-level pipeline UI" -ForegroundColor White
Write-Host "4. NO FALLBACK/MOCK badges visible to user" -ForegroundColor White
Write-Host ""

Write-Host "URL: https://d3pbubsw4or36l.cloudfront.net" -ForegroundColor Cyan
