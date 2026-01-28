# Deploy Step 1 + Step 5 + Keywords Fix to S3
# Build: GEMINI3-STEP1-STEP5-KEYWORDS-FIX-20260128

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploy Step 1 + Step 5 + Keywords Fix" -ForegroundColor Cyan
Write-Host "Build: GEMINI3-STEP1-STEP5-KEYWORDS-FIX-20260128" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$SOURCE_FILE = "Gemini3_AllSensesAI/gemini3-guardian-step1-step5-keywords-final.html"
$S3_BUCKET = "allsenses-gemini3-production"
$S3_KEY = "index.html"
$CLOUDFRONT_ID = "E2YJBHWXAMPLE"  # Replace with actual CloudFront distribution ID

# Verify source file exists
if (-not (Test-Path $SOURCE_FILE)) {
    Write-Host "❌ ERROR: Source file not found: $SOURCE_FILE" -ForegroundColor Red
    Write-Host "Run: python Gemini3_AllSensesAI/create-step1-step5-keywords-fix.py" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Source file found: $SOURCE_FILE" -ForegroundColor Green
$fileSize = (Get-Item $SOURCE_FILE).Length
Write-Host "  Size: $($fileSize / 1KB) KB" -ForegroundColor Gray
Write-Host ""

# Upload to S3
Write-Host "[1/3] Uploading to S3..." -ForegroundColor Yellow
try {
    aws s3 cp $SOURCE_FILE "s3://$S3_BUCKET/$S3_KEY" `
        --content-type "text/html" `
        --cache-control "no-cache, no-store, must-revalidate" `
        --metadata "build=GEMINI3-STEP1-STEP5-KEYWORDS-FIX-20260128,deployed=$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')"
    
    if ($LASTEXITCODE -ne 0) {
        throw "S3 upload failed"
    }
    
    Write-Host "✓ Uploaded to s3://$S3_BUCKET/$S3_KEY" -ForegroundColor Green
} catch {
    Write-Host "❌ S3 upload failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Invalidate CloudFront cache
Write-Host "[2/3] Invalidating CloudFront cache..." -ForegroundColor Yellow
try {
    $invalidation = aws cloudfront create-invalidation `
        --distribution-id $CLOUDFRONT_ID `
        --paths "/*" `
        --query 'Invalidation.Id' `
        --output text
    
    if ($LASTEXITCODE -ne 0) {
        throw "CloudFront invalidation failed"
    }
    
    Write-Host "✓ Invalidation created: $invalidation" -ForegroundColor Green
    Write-Host "  Distribution: $CLOUDFRONT_ID" -ForegroundColor Gray
} catch {
    Write-Host "⚠ CloudFront invalidation failed: $_" -ForegroundColor Yellow
    Write-Host "  You may need to wait for cache to expire or manually invalidate" -ForegroundColor Yellow
}
Write-Host ""

# Verification
Write-Host "[3/3] Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VERIFICATION STEPS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. STEP 1 VERIFICATION:" -ForegroundColor Yellow
Write-Host "   - Open the CloudFront URL in browser" -ForegroundColor White
Write-Host "   - Enter name: Ivan Demo" -ForegroundColor White
Write-Host "   - Enter phone: +573222063010" -ForegroundColor White
Write-Host "   - Click 'Complete Step 1'" -ForegroundColor White
Write-Host "   - ✓ Should see: '✅ Configuration saved'" -ForegroundColor Green
Write-Host "   - ✓ Should unlock Step 2 'Enable Location' button" -ForegroundColor Green
Write-Host ""
Write-Host "2. STEP 5 SMS PREVIEW VERIFICATION:" -ForegroundColor Yellow
Write-Host "   - On page load, Step 5 should show:" -ForegroundColor White
Write-Host "     • Victim: —" -ForegroundColor Gray
Write-Host "     • Risk: —" -ForegroundColor Gray
Write-Host "     • Recommendation: —" -ForegroundColor Gray
Write-Host "     • Message: —" -ForegroundColor Gray
Write-Host "     • Location: —" -ForegroundColor Gray
Write-Host "     • Map: —" -ForegroundColor Gray
Write-Host "     • Time: —" -ForegroundColor Gray
Write-Host "     • Action: —" -ForegroundColor Gray
Write-Host "   - After Step 1: Victim updates to 'Ivan Demo'" -ForegroundColor White
Write-Host "   - After Step 2: Location and Map update" -ForegroundColor White
Write-Host "   - After Step 4: Risk/Recommendation update" -ForegroundColor White
Write-Host ""
Write-Host "3. CONFIGURABLE KEYWORDS VERIFICATION:" -ForegroundColor Yellow
Write-Host "   - In Step 3, see 'Emergency Keywords Configuration' panel" -ForegroundColor White
Write-Host "   - Default keywords should be visible as chips" -ForegroundColor White
Write-Host "   - Add new keyword: 'ivan emergency'" -ForegroundColor White
Write-Host "   - Click 'Add Keyword' or press Enter" -ForegroundColor White
Write-Host "   - ✓ Should see new keyword chip appear" -ForegroundColor Green
Write-Host "   - Start voice detection" -ForegroundColor White
Write-Host "   - Say or type: 'ivan emergency'" -ForegroundColor White
Write-Host "   - ✓ Should trigger emergency detection" -ForegroundColor Green
Write-Host ""
Write-Host "4. CONSOLE VERIFICATION:" -ForegroundColor Yellow
Write-Host "   - Open browser console (F12)" -ForegroundColor White
Write-Host "   - Look for:" -ForegroundColor White
Write-Host "     [BUILD-VALIDATION] PASSED" -ForegroundColor Green
Write-Host "     [SMS-PREVIEW] Preview updated" -ForegroundColor Green
Write-Host "     [STEP1] Configuration saved" -ForegroundColor Green
Write-Host "     [KEYWORDS] Current keywords: [...]" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "KNOWN ISSUES (Non-Blocking):" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  • None expected - this is a comprehensive fix" -ForegroundColor White
Write-Host ""
Write-Host "Build: GEMINI3-STEP1-STEP5-KEYWORDS-FIX-20260128" -ForegroundColor Cyan
Write-Host "Deployed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host ""
