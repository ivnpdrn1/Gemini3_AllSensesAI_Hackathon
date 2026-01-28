# Deploy Victim Name in SMS to CloudFront
# Adds victim name from Step 1 to SMS preview and sent messages

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Victim Name in SMS Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$S3_BUCKET = "gemini-demo-20260127092219"
$CLOUDFRONT_DIST_ID = "E1YPPQKVA0OGX"
$SOURCE_FILE = "Gemini3_AllSensesAI/gemini3-guardian-victim-name-sms.html"
$S3_KEY = "index.html"
$BUILD_STAMP = "GEMINI3-VICTIM-NAME-SMS-20260128"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "   S3 Bucket: $S3_BUCKET"
Write-Host "   CloudFront: $CLOUDFRONT_DIST_ID"
Write-Host "   Source: $SOURCE_FILE"
Write-Host "   Build: $BUILD_STAMP"
Write-Host ""

# Verify source file exists
if (-not (Test-Path $SOURCE_FILE)) {
    Write-Host "Error: Source file not found: $SOURCE_FILE" -ForegroundColor Red
    Write-Host "   Run: python Gemini3_AllSensesAI/add-victim-name-to-sms.py" -ForegroundColor Yellow
    exit 1
}

Write-Host "Source file found" -ForegroundColor Green
Write-Host ""

# Verify build stamp
$content = Get-Content $SOURCE_FILE -Raw
if ($content -notmatch $BUILD_STAMP) {
    Write-Host "Warning: Build stamp not found in source file" -ForegroundColor Yellow
    Write-Host "   Expected: $BUILD_STAMP" -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? y/n"
    if ($continue -ne 'y') {
        Write-Host "Deployment cancelled" -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "Build stamp verified" -ForegroundColor Green
Write-Host ""

# Upload to S3
Write-Host "Uploading to S3..." -ForegroundColor Cyan
try {
    aws s3 cp $SOURCE_FILE "s3://$S3_BUCKET/$S3_KEY" `
        --content-type "text/html" `
        --cache-control "no-cache, no-store, must-revalidate" `
        --metadata "build=$BUILD_STAMP,deployed=$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')"
    
    if ($LASTEXITCODE -ne 0) {
        throw "S3 upload failed with exit code $LASTEXITCODE"
    }
    
    Write-Host "Upload successful" -ForegroundColor Green
} catch {
    Write-Host "S3 upload failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Invalidate CloudFront cache
Write-Host "Invalidating CloudFront cache..." -ForegroundColor Cyan
try {
    $invalidation = aws cloudfront create-invalidation `
        --distribution-id $CLOUDFRONT_DIST_ID `
        --paths "/*" `
        --output json | ConvertFrom-Json
    
    if ($LASTEXITCODE -ne 0) {
        throw "CloudFront invalidation failed with exit code $LASTEXITCODE"
    }
    
    $invalidationId = $invalidation.Invalidation.Id
    Write-Host "Invalidation created: $invalidationId" -ForegroundColor Green
    Write-Host "   Status: $($invalidation.Invalidation.Status)" -ForegroundColor Gray
} catch {
    Write-Host "CloudFront invalidation failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Changes Deployed:" -ForegroundColor Yellow
Write-Host "   - Victim name from Step 1 included in SMS"
Write-Host "   - Victim name appears at top of emergency alert"
Write-Host "   - Victim name in standby format"
Write-Host "   - Victim Name line item in Step 5 preview"
Write-Host "   - Proof logging for victim name"
Write-Host "   - Warning for missing victim name"
Write-Host "   - Fallback to Unknown User if empty"
Write-Host "   - Single source of truth: composeAlertSms()"
Write-Host "   - Deterministic: preview matches sent message"
Write-Host ""
Write-Host "CloudFront URL:" -ForegroundColor Cyan
Write-Host "   https://d3pbubsw4or36l.cloudfront.net" -ForegroundColor White
Write-Host ""
Write-Host "Cache invalidation in progress..." -ForegroundColor Yellow
Write-Host "   Typically completes in 20-60 seconds"
Write-Host "   Use Ctrl+Shift+R to hard refresh browser"
Write-Host ""
