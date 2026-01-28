#!/usr/bin/env pwsh
# Deploy Emergency Triggered Warning UI to CloudFront
# Build: GEMINI3-EMERGENCY-UI-20260127

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Emergency Triggered Warning UI Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$BUCKET = "gemini-demo-20260127092219"
$DISTRIBUTION_ID = "E1YPPQKVA0OGX"
$CLOUDFRONT_URL = "https://d3pbubsw4or36l.cloudfront.net"
$SOURCE_FILE = "Gemini3_AllSensesAI/gemini3-guardian-ux-enhanced.html"
$S3_KEY = "gemini3-guardian-ux-enhanced.html"

# Step 1: Upload to S3
Write-Host "[STEP 1] Uploading to S3..." -ForegroundColor Yellow
Write-Host "  Bucket: $BUCKET" -ForegroundColor Gray
Write-Host "  File: $SOURCE_FILE" -ForegroundColor Gray

try {
    aws s3 cp $SOURCE_FILE "s3://$BUCKET/$S3_KEY" `
        --content-type "text/html" `
        --cache-control "no-cache, no-store, must-revalidate" `
        --metadata "build=GEMINI3-EMERGENCY-UI-20260127,feature=emergency-triggered-warning"
    
    Write-Host "  [OK] File uploaded successfully" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Upload failed: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Create CloudFront invalidation
Write-Host ""
Write-Host "[STEP 2] Creating CloudFront invalidation..." -ForegroundColor Yellow
Write-Host "  Distribution: $DISTRIBUTION_ID" -ForegroundColor Gray

try {
    $invalidation = aws cloudfront create-invalidation `
        --distribution-id $DISTRIBUTION_ID `
        --paths "/$S3_KEY" `
        --output json | ConvertFrom-Json
    
    $invalidationId = $invalidation.Invalidation.Id
    Write-Host "  [OK] Invalidation created: $invalidationId" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Invalidation failed: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Wait for invalidation to complete
Write-Host ""
Write-Host "[STEP 3] Waiting for invalidation to complete..." -ForegroundColor Yellow
Write-Host "  This may take 1-2 minutes..." -ForegroundColor Gray

$maxWaitSeconds = 120
$waitedSeconds = 0
$checkInterval = 5

while ($waitedSeconds -lt $maxWaitSeconds) {
    Start-Sleep -Seconds $checkInterval
    $waitedSeconds += $checkInterval
    
    try {
        $status = aws cloudfront get-invalidation `
            --distribution-id $DISTRIBUTION_ID `
            --id $invalidationId `
            --output json | ConvertFrom-Json
        
        $currentStatus = $status.Invalidation.Status
        Write-Host "  Status: $currentStatus (waited ${waitedSeconds}s)" -ForegroundColor Gray
        
        if ($currentStatus -eq "Completed") {
            Write-Host "  [OK] Invalidation completed!" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "  [WARNING] Status check failed: $_" -ForegroundColor Yellow
    }
}

if ($waitedSeconds -ge $maxWaitSeconds) {
    Write-Host "  [WARNING] Invalidation still in progress after ${maxWaitSeconds}s" -ForegroundColor Yellow
    Write-Host "  The deployment will complete in the background" -ForegroundColor Yellow
}

# Step 4: Deployment summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "CloudFront URL:" -ForegroundColor Yellow
Write-Host "  $CLOUDFRONT_URL/$S3_KEY" -ForegroundColor White
Write-Host ""
Write-Host "Features Added:" -ForegroundColor Yellow
Write-Host "  [+] Emergency Banner (Global + Sticky)" -ForegroundColor Green
Write-Host "  [+] Step 3 Status Badge Update (Emergency Detected)" -ForegroundColor Green
Write-Host "  [+] Modal/Overlay (Immediate Confirmation)" -ForegroundColor Green
Write-Host "  [+] Pipeline State Updates (STEP3_EMERGENCY_TRIGGERED)" -ForegroundColor Green
Write-Host "  [+] Proof Logging (Emergency Trigger Events)" -ForegroundColor Green
Write-Host ""
Write-Host "Emergency Keywords:" -ForegroundColor Yellow
Write-Host "  emergency, help, call police, scared, following, danger, attack" -ForegroundColor White
Write-Host ""
Write-Host "Testing Instructions:" -ForegroundColor Yellow
Write-Host "  1. Complete Step 1 (Configuration)" -ForegroundColor White
Write-Host "  2. Complete Step 2 (Location)" -ForegroundColor White
Write-Host "  3. Start Voice Detection (Step 3)" -ForegroundColor White
Write-Host "  4. Say: 'it is emergency' or 'help'" -ForegroundColor White
Write-Host "  5. Observe:" -ForegroundColor White
Write-Host "     - Red Emergency Banner appears" -ForegroundColor Gray
Write-Host "     - Step 3 badge changes to 'EMERGENCY DETECTED'" -ForegroundColor Gray
Write-Host "     - Modal overlay confirms escalation" -ForegroundColor Gray
Write-Host "     - Proof log shows trigger + workflow start" -ForegroundColor Gray
Write-Host "     - Auto-advances to Step 4 (Threat Analysis)" -ForegroundColor Gray
Write-Host ""
Write-Host "Build: GEMINI3-EMERGENCY-UI-20260127" -ForegroundColor Cyan
Write-Host ""
