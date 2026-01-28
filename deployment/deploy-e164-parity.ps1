# Deploy E.164 International Parity to CloudFront
# Matches ERNIE's phone number behavior for US + International (Colombia, Mexico, Venezuela)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "E.164 International Parity Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$S3_BUCKET = "gemini-demo-20260127092219"
$CLOUDFRONT_DIST_ID = "E1YPPQKVA0OGX"
$SOURCE_FILE = "Gemini3_AllSensesAI/gemini3-guardian-e164-parity.html"
$S3_KEY = "index.html"
$BUILD_STAMP = "GEMINI3-E164-PARITY-20260128"

Write-Host "📋 Configuration:" -ForegroundColor Yellow
Write-Host "   S3 Bucket: $S3_BUCKET"
Write-Host "   CloudFront: $CLOUDFRONT_DIST_ID"
Write-Host "   Source: $SOURCE_FILE"
Write-Host "   Build: $BUILD_STAMP"
Write-Host ""

# Verify source file exists
if (-not (Test-Path $SOURCE_FILE)) {
    Write-Host "❌ Error: Source file not found: $SOURCE_FILE" -ForegroundColor Red
    Write-Host "   Run: python Gemini3_AllSensesAI/add-e164-international-parity.py" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Source file found" -ForegroundColor Green
Write-Host ""

# Verify build stamp
$content = Get-Content $SOURCE_FILE -Raw
if ($content -notmatch $BUILD_STAMP) {
    Write-Host "⚠️  Warning: Build stamp not found in source file" -ForegroundColor Yellow
    Write-Host "   Expected: $BUILD_STAMP" -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y') {
        Write-Host "Deployment cancelled" -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "✓ Build stamp verified" -ForegroundColor Green
Write-Host ""

# Upload to S3
Write-Host "📤 Uploading to S3..." -ForegroundColor Cyan
try {
    aws s3 cp $SOURCE_FILE "s3://$S3_BUCKET/$S3_KEY" `
        --content-type "text/html" `
        --cache-control "no-cache, no-store, must-revalidate" `
        --metadata "build=$BUILD_STAMP,deployed=$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')"
    
    if ($LASTEXITCODE -ne 0) {
        throw "S3 upload failed with exit code $LASTEXITCODE"
    }
    
    Write-Host "✓ Upload successful" -ForegroundColor Green
} catch {
    Write-Host "❌ S3 upload failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Invalidate CloudFront cache
Write-Host "🔄 Invalidating CloudFront cache..." -ForegroundColor Cyan
try {
    $invalidation = aws cloudfront create-invalidation `
        --distribution-id $CLOUDFRONT_DIST_ID `
        --paths "/*" `
        --output json | ConvertFrom-Json
    
    if ($LASTEXITCODE -ne 0) {
        throw "CloudFront invalidation failed with exit code $LASTEXITCODE"
    }
    
    $invalidationId = $invalidation.Invalidation.Id
    Write-Host "✓ Invalidation created: $invalidationId" -ForegroundColor Green
    Write-Host "   Status: $($invalidation.Invalidation.Status)" -ForegroundColor Gray
} catch {
    Write-Host "❌ CloudFront invalidation failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Changes Deployed:" -ForegroundColor Yellow
Write-Host "   ✓ Phone placeholder: +1XXXXXXXXXX, +57XXXXXXXXXX, +52XXXXXXXXXX, +58XXXXXXXXXX"
Write-Host "   ✓ Helper text: E.164 format with examples"
Write-Host "   ✓ Validation feedback: Real-time green/red messages"
Write-Host "   ✓ International support note: US, Colombia, Mexico, Venezuela"
Write-Host "   ✓ E.164 regex validation: ^\+[1-9]\d{6,14}$"
Write-Host "   ✓ Country detection: US, Colombia, Mexico, Venezuela"
Write-Host "   ✓ Form submission blocking: Invalid numbers cannot proceed"
Write-Host ""
Write-Host "🌐 CloudFront URL:" -ForegroundColor Cyan
Write-Host "   https://d3pbubsw4or36l.cloudfront.net" -ForegroundColor White
Write-Host ""
Write-Host "⏱️  Cache invalidation in progress..." -ForegroundColor Yellow
Write-Host "   Typically completes in 20-60 seconds"
Write-Host "   Use Ctrl+Shift+R to hard refresh browser"
Write-Host ""
Write-Host "🧪 Test Cases:" -ForegroundColor Cyan
Write-Host "   Valid:"
Write-Host "     • +14155552671 (US)"
Write-Host "     • +573001234567 (Colombia)"
Write-Host "     • +5215512345678 (Mexico)"
Write-Host "     • +584121234567 (Venezuela)"
Write-Host ""
Write-Host "   Invalid:"
Write-Host "     • 14155552671 (missing +)"
Write-Host "     • +1 (too short)"
Write-Host "     • +57 3001234567 (spaces)"
Write-Host "     • +52-55-1234-5678 (dashes)"
Write-Host ""
Write-Host "📝 Verification Steps:" -ForegroundColor Yellow
Write-Host "   1. Open CloudFront URL in browser"
Write-Host "   2. Hard refresh (Ctrl+Shift+R)"
Write-Host "   3. Verify build stamp: $BUILD_STAMP"
Write-Host "   4. Check Step 1 phone input placeholder"
Write-Host "   5. Test validation with valid/invalid numbers"
Write-Host "   6. Confirm green ✓ for valid, red ✗ for invalid"
Write-Host "   7. Verify international support note is visible"
Write-Host ""
