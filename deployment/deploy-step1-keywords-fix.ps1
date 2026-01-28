# Deploy Step 1 Fix + Keywords Field to CloudFront
# FIX A: Step 1 button click not working (must unblock Step 2/3)
# FIX B: Add configurable emergency keywords field

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 1 Fix + Keywords Field Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$S3_BUCKET = "gemini-demo-20260127092219"
$CLOUDFRONT_DIST_ID = "E1YPPQKVA0OGX"
$SOURCE_FILE = "Gemini3_AllSensesAI/gemini3-guardian-step1-keywords-fix.html"
$S3_KEY = "index.html"
$BUILD_STAMP = "GEMINI3-STEP1-KEYWORDS-FIX-20260128"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "   S3 Bucket: $S3_BUCKET"
Write-Host "   CloudFront: $CLOUDFRONT_DIST_ID"
Write-Host "   Source: $SOURCE_FILE"
Write-Host "   Build: $BUILD_STAMP"
Write-Host ""

# Verify source file exists
if (-not (Test-Path $SOURCE_FILE)) {
    Write-Host "Error: Source file not found: $SOURCE_FILE" -ForegroundColor Red
    Write-Host "   Run: python Gemini3_AllSensesAI/fix-step1-and-add-keywords.py" -ForegroundColor Yellow
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
Write-Host "   FIX A: Step 1 Button Click Not Working"
Write-Host "     - Button has stable ID: completeStep1Btn"
Write-Host "     - Button type: button (prevents form submit)"
Write-Host "     - Hard-bound click handler in DOMContentLoaded"
Write-Host "     - event.preventDefault() in handler"
Write-Host "     - Step 1 proof box with logging"
Write-Host "     - Try/catch error handling"
Write-Host "     - Console logging for debugging"
Write-Host "     - Unlocks Step 2 (Enable Location button)"
Write-Host "     - Updates pipeline state to STEP1_COMPLETE"
Write-Host ""
Write-Host "   FIX B: Add Emergency Keywords Field"
Write-Host "     - Add keywords UI in Step 3"
Write-Host "     - Text input for comma-separated keywords"
Write-Host "     - Add Keywords button"
Write-Host "     - Reset to Defaults button"
Write-Host "     - localStorage persistence"
Write-Host "     - Merge with defaults (dedupe)"
Write-Host "     - Case-insensitive matching"
Write-Host "     - Applies to voice AND manual text"
Write-Host "     - Trigger rule UI updates"
Write-Host "     - Enter key support in input field"
Write-Host ""
Write-Host "CloudFront URL:" -ForegroundColor Cyan
Write-Host "   https://d3pbubsw4or36l.cloudfront.net" -ForegroundColor White
Write-Host ""
Write-Host "Cache invalidation in progress..." -ForegroundColor Yellow
Write-Host "   Typically completes in 20-60 seconds"
Write-Host "   Use Ctrl+Shift+R to hard refresh browser"
Write-Host ""
Write-Host "Test Cases:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   FIX A - Step 1 Button Click:" -ForegroundColor Yellow
Write-Host "     1. Open app, enter name and phone"
Write-Host "     2. Click Complete Step 1 button"
Write-Host "     3. Verify Step 1 proof box shows logs:"
Write-Host "        - [STEP1] Click received"
Write-Host "        - [STEP1] Phone valid: true"
Write-Host "        - [STEP1] Configuration saved"
Write-Host "        - [STEP1] Step 2 unlocked"
Write-Host "     4. Verify Step 1 status: Configuration saved"
Write-Host "     5. Verify Enable Location button is enabled"
Write-Host "     6. Verify Step 2 proof box shows: Step 1 complete!"
Write-Host ""
Write-Host "   FIX B - Emergency Keywords Field:" -ForegroundColor Yellow
Write-Host "     1. Complete Steps 1 and 2"
Write-Host "     2. In Step 3, find Add Emergency Keywords section"
Write-Host "     3. Enter custom keywords: knife, stop following me, danger"
Write-Host "     4. Click Add Keywords button"
Write-Host "     5. Verify status: Added X new keyword(s)"
Write-Host "     6. Verify Trigger Rule UI shows updated keywords"
Write-Host "     7. Test voice detection: Say knife"
Write-Host "     8. Verify keyword detected in console: [TRIGGER] Keyword matched: knife (source: voice)"
Write-Host "     9. Test manual text: Type danger in Step 4 textarea"
Write-Host "     10. Verify keyword detected: [TRIGGER] Keyword matched: danger (source: manual)"
Write-Host "     11. Refresh page, verify keywords persist"
Write-Host "     12. Click Reset to Defaults, verify keywords reset"
Write-Host ""
Write-Host "Verification Steps:" -ForegroundColor Yellow
Write-Host "   1. Open CloudFront URL in browser"
Write-Host "   2. Hard refresh (Ctrl+Shift+R)"
Write-Host "   3. Verify build stamp: $BUILD_STAMP"
Write-Host "   4. Test Step 1 button click progression"
Write-Host "   5. Test adding custom keywords"
Write-Host "   6. Test keyword detection in voice and manual text"
Write-Host "   7. Test localStorage persistence (refresh page)"
Write-Host "   8. Test Reset to Defaults button"
Write-Host ""
