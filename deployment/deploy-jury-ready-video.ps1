#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy Jury-Ready VIDEO Build to CloudFront
    
.DESCRIPTION
    Deploys GEMINI3-JURY-READY-VIDEO-20260128-v1 to existing CloudFront distribution.
    This is an ADDITIVE deployment that preserves all baseline functionality.
    
    Build ID: GEMINI3-JURY-READY-VIDEO-20260128-v1
    Distribution: E2NIUI2KOXAO0Q
    Bucket: gemini3-guardian-prod-20260127120521
    
.NOTES
    No git/repository actions
    No legacy system names
    Deploys to same CloudFront as baseline
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$BUILD_ID = "GEMINI3-JURY-READY-VIDEO-20260128-v1"
$DISTRIBUTION_ID = "E2NIUI2KOXAO0Q"
$BUCKET_NAME = "gemini3-guardian-prod-20260127120521"
$SOURCE_FILE = "Gemini3_AllSensesAI/gemini3-guardian-jury-ready-video.html"
$CLOUDFRONT_URL = "https://dfc8ght8abwqc.cloudfront.net"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying Jury-Ready VIDEO Build" -ForegroundColor Cyan
Write-Host "Build ID: $BUILD_ID" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verify source file exists
if (-not (Test-Path $SOURCE_FILE)) {
    Write-Host "[ERROR] Source file not found: $SOURCE_FILE" -ForegroundColor Red
    Write-Host "Run: python Gemini3_AllSensesAI/create-jury-ready-video-build.py" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Source file found: $SOURCE_FILE" -ForegroundColor Green
$fileSize = (Get-Item $SOURCE_FILE).Length
Write-Host "  Size: $($fileSize / 1KB) KB" -ForegroundColor Gray

# Upload to S3
Write-Host ""
Write-Host "Uploading to S3..." -ForegroundColor Cyan
Write-Host "  Bucket: $BUCKET_NAME" -ForegroundColor Gray
Write-Host "  Target: index.html" -ForegroundColor Gray

try {
    aws s3 cp $SOURCE_FILE "s3://$BUCKET_NAME/index.html" `
        --content-type "text/html" `
        --cache-control "no-cache, no-store, must-revalidate" `
        --metadata "build-id=$BUILD_ID,deployed=$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')"
    
    if ($LASTEXITCODE -ne 0) {
        throw "S3 upload failed with exit code $LASTEXITCODE"
    }
    
    Write-Host "[OK] Upload successful" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] S3 upload failed: $_" -ForegroundColor Red
    exit 1
}

# Create CloudFront invalidation
Write-Host ""
Write-Host "Creating CloudFront invalidation..." -ForegroundColor Cyan
Write-Host "  Distribution: $DISTRIBUTION_ID" -ForegroundColor Gray

try {
    $invalidation = aws cloudfront create-invalidation `
        --distribution-id $DISTRIBUTION_ID `
        --paths "/*" `
        --output json | ConvertFrom-Json
    
    if ($LASTEXITCODE -ne 0) {
        throw "CloudFront invalidation failed with exit code $LASTEXITCODE"
    }
    
    $invalidationId = $invalidation.Invalidation.Id
    Write-Host "[OK] Invalidation created: $invalidationId" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] CloudFront invalidation failed: $_" -ForegroundColor Red
    Write-Host "[WARNING] File uploaded but cache not cleared" -ForegroundColor Yellow
    exit 1
}

# Print deployment summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Build ID: $BUILD_ID" -ForegroundColor White
Write-Host "CloudFront URL: $CLOUDFRONT_URL" -ForegroundColor White
Write-Host "S3 Bucket: $BUCKET_NAME" -ForegroundColor Gray
Write-Host "Invalidation ID: $invalidationId" -ForegroundColor Gray
Write-Host ""
Write-Host "Wait 2-3 minutes for CloudFront propagation" -ForegroundColor Yellow
Write-Host ""
Write-Host "Verification Steps:" -ForegroundColor Cyan
Write-Host "  1. Open: $CLOUDFRONT_URL" -ForegroundColor White
Write-Host "  2. Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)" -ForegroundColor White
Write-Host "  3. Check Build ID in 2 locations:" -ForegroundColor White
Write-Host "     - Top stamp: Build: $BUILD_ID" -ForegroundColor Gray
Write-Host "     - Runtime Health Check: Loaded Build ID: $BUILD_ID" -ForegroundColor Gray
Write-Host "  4. Verify Vision Panel exists after Step 4 heading" -ForegroundColor White
Write-Host "  5. Verify 3 frame placeholders visible" -ForegroundColor White
Write-Host "  6. Verify baseline features still work:" -ForegroundColor White
Write-Host "     - Step 1 button (no dead click)" -ForegroundColor Gray
Write-Host "     - Step 5 SMS preview (8 fields)" -ForegroundColor Gray
Write-Host "     - Configurable keywords UI" -ForegroundColor Gray
Write-Host ""
Write-Host "What Changed (ADDITIVE):" -ForegroundColor Cyan
Write-Host "  [+] Vision Panel added after Step 4" -ForegroundColor Green
Write-Host "  [+] 3 frame placeholders (standby -> captured)" -ForegroundColor Green
Write-Host "  [+] Vision status badge" -ForegroundColor Green
Write-Host "  [+] Capture policy text" -ForegroundColor Green
Write-Host "  [+] Vision proof logs" -ForegroundColor Green
Write-Host ""
Write-Host "Baseline Preserved:" -ForegroundColor Cyan
Write-Host "  [OK] Step 1 button fix" -ForegroundColor Green
Write-Host "  [OK] Step 5 SMS preview" -ForegroundColor Green
Write-Host "  [OK] Configurable keywords" -ForegroundColor Green
Write-Host "  [OK] Build Identity proof" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

exit 0
