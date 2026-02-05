# Deploy Yandex Elimination Fix to Production
# Eliminates all Yandex Maps references and replaces with Google Maps

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Write-Host "=== Deploy Yandex Elimination Fix ===" -ForegroundColor Cyan
Write-Host ""

# Configuration
$S3_BUCKET = "gemini3-guardian-prod-20260127120521"
$CLOUDFRONT_DIST_ID = "E2NIUI2KOXAO0Q"
$CLOUDFRONT_URL = "https://dfc8ght8abwqc.cloudfront.net"
$LOCAL_FILE = "Gemini3_AllSensesAI/gemini3-guardian-production-sms-video-REBUILT.html"
$BUILD_ID = "KILL-SWITCH-REBUILD-20260203"

# Verify local file is clean
Write-Host "[STEP 1] Verifying local file is clean..." -ForegroundColor Yellow
$yandexMatches = Select-String -Path $LOCAL_FILE -Pattern "yandex" -AllMatches -CaseSensitive:$false
$yandexCount = if ($yandexMatches) { $yandexMatches.Count } else { 0 }
if ($yandexCount -gt 0) {
    Write-Host "[ERROR] Local file still has $yandexCount Yandex references!" -ForegroundColor Red
    exit 1
}
Write-Host "[PASS] Local file is clean (0 Yandex references)" -ForegroundColor Green

# Verify Google Maps implementation
$googleMatches = Select-String -Path $LOCAL_FILE -Pattern "maps\.google|maps\.googleapis" -AllMatches
$googleCount = if ($googleMatches) { $googleMatches.Count } else { 0 }
if ($googleCount -eq 0) {
    Write-Host "[ERROR] No Google Maps implementation found!" -ForegroundColor Red
    exit 1
}
Write-Host "[PASS] Google Maps implementation found ($googleCount references)" -ForegroundColor Green

# Verify buildStamp
$buildStamp = Select-String -Path $LOCAL_FILE -Pattern "Build: $BUILD_ID"
if (-not $buildStamp) {
    Write-Host "[ERROR] BuildStamp mismatch! Expected: $BUILD_ID" -ForegroundColor Red
    exit 1
}
Write-Host "[PASS] BuildStamp verified: $BUILD_ID" -ForegroundColor Green

Write-Host ""
Write-Host "[STEP 2] Uploading to S3..." -ForegroundColor Yellow
Write-Host "Bucket: $S3_BUCKET" -ForegroundColor Gray
Write-Host "Key: index.html" -ForegroundColor Gray

try {
    aws s3 cp $LOCAL_FILE "s3://$S3_BUCKET/index.html" `
        --content-type "text/html; charset=utf-8" `
        --cache-control "max-age=0,no-cache,no-store,must-revalidate" `
        --metadata-directive REPLACE
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] S3 upload failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host "[SUCCESS] Uploaded to S3" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] S3 upload exception: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[STEP 3] Invalidating CloudFront cache..." -ForegroundColor Yellow
Write-Host "Distribution: $CLOUDFRONT_DIST_ID" -ForegroundColor Gray
Write-Host "Paths: / and /index.html" -ForegroundColor Gray

try {
    $invalidation = aws cloudfront create-invalidation `
        --distribution-id $CLOUDFRONT_DIST_ID `
        --paths "/" "/index.html" `
        --output json | ConvertFrom-Json
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] CloudFront invalidation failed!" -ForegroundColor Red
        exit 1
    }
    
    $invalidationId = $invalidation.Invalidation.Id
    Write-Host "[SUCCESS] Invalidation created: $invalidationId" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Waiting for invalidation to complete..." -ForegroundColor Yellow
    
    $maxWait = 60
    $waited = 0
    while ($waited -lt $maxWait) {
        Start-Sleep -Seconds 5
        $waited += 5
        
        $status = aws cloudfront get-invalidation `
            --distribution-id $CLOUDFRONT_DIST_ID `
            --id $invalidationId `
            --query "Invalidation.Status" `
            --output text
        
        Write-Host "  Status: $status (waited ${waited}s)" -ForegroundColor Gray
        
        if ($status -eq "Completed") {
            Write-Host "[SUCCESS] Invalidation completed!" -ForegroundColor Green
            break
        }
    }
    
    if ($waited -ge $maxWait) {
        Write-Host "[WARNING] Invalidation still in progress after ${maxWait}s" -ForegroundColor Yellow
        Write-Host "          Continue with verification anyway..." -ForegroundColor Yellow
    }
} catch {
    Write-Host "[ERROR] CloudFront invalidation exception: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[STEP 4] Verifying deployment..." -ForegroundColor Yellow
Write-Host "Waiting 10 seconds for propagation..." -ForegroundColor Gray
Start-Sleep -Seconds 10

try {
    $response = Invoke-WebRequest -Uri $CLOUDFRONT_URL -UseBasicParsing
    $content = $response.Content
    
    # Check for Yandex
    if ($content -match "yandex") {
        Write-Host "[FAIL] CloudFront still serving Yandex!" -ForegroundColor Red
        Write-Host "       Try hard refresh in Incognito: Ctrl+Shift+R" -ForegroundColor Yellow
    } else {
        Write-Host "[PASS] No Yandex references in CloudFront response" -ForegroundColor Green
    }
    
    # Check for Google Maps
    if ($content -match "maps\.google|maps\.googleapis") {
        Write-Host "[PASS] Google Maps implementation found" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] No Google Maps implementation found!" -ForegroundColor Red
    }
    
    # Check buildStamp
    if ($content -match $BUILD_ID) {
        Write-Host "[PASS] BuildStamp verified: $BUILD_ID" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] BuildStamp mismatch!" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] Verification failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== DEPLOYMENT COMPLETE ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "BROWSER VERIFICATION REQUIRED:" -ForegroundColor Yellow
Write-Host "1. CLOSE all browser windows" -ForegroundColor White
Write-Host "2. Open NEW Incognito window (Ctrl+Shift+N)" -ForegroundColor White
Write-Host "3. Go to: $CLOUDFRONT_URL" -ForegroundColor Cyan
Write-Host "4. Press Ctrl+Shift+R (hard refresh)" -ForegroundColor White
Write-Host "5. Open DevTools (F12) → Console + Network tabs" -ForegroundColor White
Write-Host "6. Complete Steps 1-2 (Enable Location or Use Demo Location)" -ForegroundColor White
Write-Host "7. Verify map preview shows NO Yandex logo/watermark" -ForegroundColor White
Write-Host "8. Check Console for: [STEP2][MAP] preview loaded (google)" -ForegroundColor White
Write-Host "9. Check Network tab for NO requests to yandex.ru domains" -ForegroundColor White
Write-Host ""
Write-Host "EXPECTED CONSOLE LOGS:" -ForegroundColor Yellow
Write-Host "  [STEP2][MAP] Using Google Static Maps API with key" -ForegroundColor Gray
Write-Host "  OR" -ForegroundColor Gray
Write-Host "  [STEP2][MAP] Using Google Maps embed (no key)" -ForegroundColor Gray
Write-Host "  [STEP2][MAP] preview loaded (google)" -ForegroundColor Gray
Write-Host ""
Write-Host "If still seeing Yandex:" -ForegroundColor Yellow
Write-Host "  - Try different browser (Edge, Firefox)" -ForegroundColor Gray
Write-Host "  - Clear browser cache completely" -ForegroundColor Gray
Write-Host "  - Wait 5 more minutes for CDN propagation" -ForegroundColor Gray
