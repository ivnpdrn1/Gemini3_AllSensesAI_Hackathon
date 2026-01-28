# Deploy SMS Preview Complete to CloudFront
# Tasks A, B, C, D: Always-visible preview, live updates, keyword detection, emergency state

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SMS Preview Complete Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$S3_BUCKET = "gemini-demo-20260127092219"
$CLOUDFRONT_DIST_ID = "E1YPPQKVA0OGX"
$SOURCE_FILE = "Gemini3_AllSensesAI/gemini3-guardian-sms-preview-complete.html"
$S3_KEY = "index.html"
$BUILD_STAMP = "GEMINI3-SMS-PREVIEW-COMPLETE-20260128"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "   S3 Bucket: $S3_BUCKET"
Write-Host "   CloudFront: $CLOUDFRONT_DIST_ID"
Write-Host "   Source: $SOURCE_FILE"
Write-Host "   Build: $BUILD_STAMP"
Write-Host ""

# Verify source file exists
if (-not (Test-Path $SOURCE_FILE)) {
    Write-Host "❌ Error: Source file not found: $SOURCE_FILE" -ForegroundColor Red
    Write-Host "   Run: python Gemini3_AllSensesAI/add-sms-preview-complete.py" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Source file found" -ForegroundColor Green
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

Write-Host "✓ Build stamp verified" -ForegroundColor Green
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
    
    Write-Host "✓ Upload successful" -ForegroundColor Green
} catch {
    Write-Host "❌ S3 upload failed: $_" -ForegroundColor Red
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
    Write-Host "✓ Invalidation created: $invalidationId" -ForegroundColor Green
    Write-Host "   Status: $($invalidation.Invalidation.Status)" -ForegroundColor Gray
} catch {
    Write-Host "❌ CloudFront invalidation failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Changes Deployed:" -ForegroundColor Yellow
Write-Host "   - TASK A: Always-visible SMS Preview panel"
Write-Host "   - TASK B: Live updates on all input changes"
Write-Host "   - TASK C: Emergency keyword detection (voice + manual)"
Write-Host "   - TASK D: SMS format reflects emergency trigger state"
Write-Host ""
Write-Host "Features:" -ForegroundColor Cyan
Write-Host "   - Standby states: Add emergency contact, Enable location"
Write-Host "   - Emergency keywords: emergency, help, call 911, scared, following, danger, attack"
Write-Host "   - Keyword detection in voice transcript (Step 3)"
Write-Host "   - Keyword detection in manual textarea (Step 4)"
Write-Host "   - Trigger Rule UI blocks in Step 3 and Step 4"
Write-Host "   - SMS format: Emergency Alert vs Standby"
Write-Host "   - Live preview updates on contact/name/location/transcript/analysis changes"
Write-Host "   - Single source of truth: composeAlertSms()"
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
Write-Host "   TASK A - Always-Visible Panel:" -ForegroundColor Yellow
Write-Host "     1. Open app, verify SMS Preview panel visible in Step 5"
Write-Host "     2. Before Step 1: Add emergency contact in Step 1"
Write-Host "     3. After Step 1, before Step 2: Enable location in Step 2"
Write-Host "     4. After Step 2: Preview shows standby format"
Write-Host ""
Write-Host "   TASK B - Live Updates:" -ForegroundColor Yellow
Write-Host "     1. Change contact number - preview updates"
Write-Host "     2. Change victim name - preview updates"
Write-Host "     3. Enable location - preview updates"
Write-Host "     4. Type in Step 4 textarea - preview updates"
Write-Host "     5. Run threat analysis - preview updates"
Write-Host ""
Write-Host "   TASK C - Keyword Detection:" -ForegroundColor Yellow
Write-Host "     1. Voice (Step 3): Say help - keyword detected"
Write-Host "     2. Manual (Step 4): Type emergency - keyword detected"
Write-Host "     3. Verify Trigger Rule UI updates in both steps"
Write-Host "     4. Check console logs: TRIGGER Keyword matched"
Write-Host ""
Write-Host "   TASK D - Emergency State:" -ForegroundColor Yellow
Write-Host "     1. Before keyword: Standby format"
Write-Host "     2. After keyword: Emergency Alert format"
Write-Host "     3. Verify SMS includes: Risk, Recommendation, Message, Location, Maps link"
Write-Host "     4. Verify checklist shows green checkmarks for emergency"
Write-Host ""
Write-Host "Verification Steps:" -ForegroundColor Yellow
Write-Host "   1. Open CloudFront URL in browser"
Write-Host "   2. Hard refresh (Ctrl+Shift+R)"
Write-Host "   3. Verify build stamp: $BUILD_STAMP"
Write-Host "   4. Complete Steps 1-2"
Write-Host "   5. Verify SMS Preview always visible"
Write-Host "   6. Test keyword detection in Step 3 (voice) and Step 4 (manual)"
Write-Host "   7. Verify SMS format changes based on emergency state"
Write-Host "   8. Test live updates on all input changes"
Write-Host ""

