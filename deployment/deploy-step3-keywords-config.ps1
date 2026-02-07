# Deploy Step 3 Emergency Keywords Configuration to CloudFront
# Deploys: gemini3-guardian-production-sms-FINAL.html with Step 3 Keywords UI

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 3 Keywords Configuration Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$S3_BUCKET = "gemini3-guardian-prod-20260127120521"
$CLOUDFRONT_DIST_ID = "E2NIUI2KOXAO0Q"
$SOURCE_FILE = "Gemini3_AllSensesAI/gemini3-guardian-production-sms-FINAL.html"
$S3_KEY = "index.html"
$BUILD_STAMP = "GEMINI3-GUARDIAN-SMS-FINAL-STEP3-KEYWORDS"
$CHECKPOINT_TAG = "v2026.02.05-step3-emergency-keywords-stable"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "   S3 Bucket: $S3_BUCKET"
Write-Host "   CloudFront: $CLOUDFRONT_DIST_ID"
Write-Host "   Source: $SOURCE_FILE"
Write-Host "   Checkpoint: $CHECKPOINT_TAG"
Write-Host ""

# Verify source file exists
if (-not (Test-Path $SOURCE_FILE)) {
    Write-Host "Error: Source file not found: $SOURCE_FILE" -ForegroundColor Red
    Write-Host "   Expected: $SOURCE_FILE" -ForegroundColor Yellow
    exit 1
}

Write-Host "[1/5] Source file found" -ForegroundColor Green
Write-Host ""

# Verify Step 3 keywords UI is present
$content = Get-Content $SOURCE_FILE -Raw
if ($content -notmatch "keywords-config") {
    Write-Host "Error: Step 3 keywords UI not found in source file" -ForegroundColor Red
    Write-Host "   Missing: keywords-config class" -ForegroundColor Yellow
    exit 1
}

if ($content -notmatch "EmergencyKeywordsConfig") {
    Write-Host "Error: EmergencyKeywordsConfig class not found in source file" -ForegroundColor Red
    exit 1
}

Write-Host "[2/5] Step 3 keywords UI verified" -ForegroundColor Green
Write-Host ""

# Upload to S3
Write-Host "[3/5] Uploading to S3..." -ForegroundColor Cyan
try {
    aws s3 cp $SOURCE_FILE "s3://$S3_BUCKET/$S3_KEY" `
        --content-type "text/html" `
        --cache-control "no-cache, no-store, must-revalidate" `
        --metadata "checkpoint=$CHECKPOINT_TAG,deployed=$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')"
    
    if ($LASTEXITCODE -ne 0) {
        throw "S3 upload failed with exit code $LASTEXITCODE"
    }
    
    Write-Host "   Upload successful" -ForegroundColor Green
} catch {
    Write-Host "   S3 upload failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Invalidate CloudFront cache
Write-Host "[4/5] Invalidating CloudFront cache..." -ForegroundColor Cyan
try {
    $invalidation = aws cloudfront create-invalidation `
        --distribution-id $CLOUDFRONT_DIST_ID `
        --paths "/*" `
        --output json | ConvertFrom-Json
    
    if ($LASTEXITCODE -ne 0) {
        throw "CloudFront invalidation failed with exit code $LASTEXITCODE"
    }
    
    $invalidationId = $invalidation.Invalidation.Id
    Write-Host "   Invalidation created: $invalidationId" -ForegroundColor Green
    Write-Host "   Status: $($invalidation.Invalidation.Status)" -ForegroundColor Gray
} catch {
    Write-Host "   CloudFront invalidation failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Wait for invalidation to complete (optional)
Write-Host "[5/5] Waiting for invalidation to complete..." -ForegroundColor Cyan
Write-Host "   This typically takes 20-60 seconds" -ForegroundColor Gray
Write-Host ""

$maxWaitSeconds = 120
$waitedSeconds = 0
$checkInterval = 10

while ($waitedSeconds -lt $maxWaitSeconds) {
    Start-Sleep -Seconds $checkInterval
    $waitedSeconds += $checkInterval
    
    try {
        $status = aws cloudfront get-invalidation `
            --distribution-id $CLOUDFRONT_DIST_ID `
            --id $invalidationId `
            --output json | ConvertFrom-Json
        
        $currentStatus = $status.Invalidation.Status
        Write-Host "   Status: $currentStatus (waited $waitedSeconds seconds)" -ForegroundColor Gray
        
        if ($currentStatus -eq "Completed") {
            Write-Host "   Invalidation complete!" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "   Warning: Could not check invalidation status" -ForegroundColor Yellow
        break
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Deployed Features:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Step 1: Configuration" -ForegroundColor White
Write-Host "     - Victim name and emergency contact" -ForegroundColor Gray
Write-Host "     - Phone validation" -ForegroundColor Gray
Write-Host "     - Configuration persistence" -ForegroundColor Gray
Write-Host ""
Write-Host "   Step 2: Location Services" -ForegroundColor White
Write-Host "     - Google Maps integration" -ForegroundColor Gray
Write-Host "     - Live location preview" -ForegroundColor Gray
Write-Host "     - Demo mode support" -ForegroundColor Gray
Write-Host "     - Fail-safe GPS handling" -ForegroundColor Gray
Write-Host ""
Write-Host "   Step 3: Emergency Keywords Configuration (NEW)" -ForegroundColor White
Write-Host "     - Add/remove custom keywords" -ForegroundColor Gray
Write-Host "     - Keyword counter display" -ForegroundColor Gray
Write-Host "     - Empty state handling" -ForegroundColor Gray
Write-Host "     - localStorage persistence" -ForegroundColor Gray
Write-Host "     - Integration with emergency detection" -ForegroundColor Gray
Write-Host "     - Enter key support" -ForegroundColor Gray
Write-Host "     - Default keywords: emergency, help, call police, scared, following, danger, attack" -ForegroundColor Gray
Write-Host ""

Write-Host "CloudFront URL:" -ForegroundColor Cyan
Write-Host "   https://dfc8ght8abwqc.cloudfront.net" -ForegroundColor White
Write-Host ""

Write-Host "Git Checkpoint:" -ForegroundColor Cyan
Write-Host "   Tag: $CHECKPOINT_TAG" -ForegroundColor White
Write-Host "   Commit: 066e058" -ForegroundColor White
Write-Host "   Branch: main" -ForegroundColor White
Write-Host ""

Write-Host "Verification Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   1. Open CloudFront URL in NEW Incognito window" -ForegroundColor White
Write-Host "      https://dfc8ght8abwqc.cloudfront.net" -ForegroundColor Cyan
Write-Host ""
Write-Host "   2. Hard refresh (Ctrl+Shift+R or Cmd+Shift+R)" -ForegroundColor White
Write-Host ""
Write-Host "   3. Complete Step 1 and Step 2" -ForegroundColor White
Write-Host ""
Write-Host "   4. In Step 3, verify Emergency Keywords Configuration UI:" -ForegroundColor White
Write-Host "      - Keywords config panel visible" -ForegroundColor Gray
Write-Host "      - Keyword counter shows: (Keywords: 7)" -ForegroundColor Gray
Write-Host "      - Default keywords displayed as chips" -ForegroundColor Gray
Write-Host "      - Input field and Add button present" -ForegroundColor Gray
Write-Host ""
Write-Host "   5. Test Add Keyword:" -ForegroundColor White
Write-Host "      - Type 'test keyword' in input" -ForegroundColor Gray
Write-Host "      - Click Add or press Enter" -ForegroundColor Gray
Write-Host "      - Verify keyword appears as chip" -ForegroundColor Gray
Write-Host "      - Verify counter updates: (Keywords: 8)" -ForegroundColor Gray
Write-Host ""
Write-Host "   6. Test Remove Keyword:" -ForegroundColor White
Write-Host "      - Click X button on a keyword chip" -ForegroundColor Gray
Write-Host "      - Verify keyword removed" -ForegroundColor Gray
Write-Host "      - Verify counter updates" -ForegroundColor Gray
Write-Host ""
Write-Host "   7. Test Persistence:" -ForegroundColor White
Write-Host "      - Refresh page (F5)" -ForegroundColor Gray
Write-Host "      - Verify keywords persist after reload" -ForegroundColor Gray
Write-Host ""
Write-Host "   8. Test Duplicate Prevention:" -ForegroundColor White
Write-Host "      - Try adding existing keyword" -ForegroundColor Gray
Write-Host "      - Verify duplicate rejected (case-insensitive)" -ForegroundColor Gray
Write-Host ""
Write-Host "   9. Test Empty State:" -ForegroundColor White
Write-Host "      - Remove all keywords" -ForegroundColor Gray
Write-Host "      - Verify empty state message appears" -ForegroundColor Gray
Write-Host ""
Write-Host "   10. Verify Zero Regression:" -ForegroundColor White
Write-Host "       - Step 1 still works correctly" -ForegroundColor Gray
Write-Host "       - Step 2 still works correctly" -ForegroundColor Gray
Write-Host "       - No console errors" -ForegroundColor Gray
Write-Host ""

Write-Host "Documentation:" -ForegroundColor Cyan
Write-Host "   - CHECKPOINT_STEP3_EMERGENCY_KEYWORDS_COMPLETE.md" -ForegroundColor White
Write-Host "   - STEP3_KEYWORDS_VERIFICATION_REPORT.md" -ForegroundColor White
Write-Host "   - STEP3_KEYWORDS_QUICK_TEST_GUIDE.md" -ForegroundColor White
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Verify deployment in browser" -ForegroundColor White
Write-Host "   2. Test all Step 3 keywords features" -ForegroundColor White
Write-Host "   3. Confirm zero regression in Steps 1 & 2" -ForegroundColor White
Write-Host "   4. Document active features for next development phase" -ForegroundColor White
Write-Host ""

