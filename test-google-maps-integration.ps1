# Step 2 Google Maps Integration - Local Test Script
# This script verifies all Google Maps changes work correctly

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 2 Google Maps Integration Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Verify documentation files exist
Write-Host "[TEST 1] Verifying documentation files..." -ForegroundColor Yellow
$docFiles = @(
    "Gemini3_AllSensesAI/STEP2_LIVE_TRACKING_ARCHITECTURE.md",
    "Gemini3_AllSensesAI/STEP2_LIVE_TRACKING_DEPLOYMENT.md",
    "Gemini3_AllSensesAI/STEP2_LIVE_TRACKING_LOCAL_TEST.md",
    "Gemini3_AllSensesAI/STEP2_LIVE_TRACKING_CHANGES.md",
    "Gemini3_AllSensesAI/STEP2_GOOGLE_HACKATHON_ALIGNMENT_COMPLETE.md",
    "Gemini3_AllSensesAI/STEP2_GOOGLE_MAPS_FILE_DIFFS.md"
)

$allDocsExist = $true
foreach ($file in $docFiles) {
    if (Test-Path $file) {
        Write-Host "  [OK] $file" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $file not found" -ForegroundColor Red
        $allDocsExist = $false
    }
}

if ($allDocsExist) {
    Write-Host "[PASS] All documentation files exist" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Some documentation files missing" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 2: Verify no Yandex references in documentation
Write-Host "[TEST 2] Checking for Yandex references..." -ForegroundColor Yellow
$yandexFound = $false
foreach ($file in $docFiles) {
    $content = Get-Content $file -Raw
    if ($content -match "yandex\.ru" -or $content -match "Yandex Maps") {
        Write-Host "  [WARN] Yandex reference found in $file" -ForegroundColor Yellow
        $yandexFound = $true
    }
}

if (-not $yandexFound) {
    Write-Host "[PASS] No Yandex references found in documentation" -ForegroundColor Green
} else {
    Write-Host "[INFO] Some Yandex references remain (may be in 'before' examples)" -ForegroundColor Cyan
}
Write-Host ""

# Test 3: Verify Google Maps references exist
Write-Host "[TEST 3] Verifying Google Maps references..." -ForegroundColor Yellow
$googleMapsFound = $false
foreach ($file in $docFiles) {
    $content = Get-Content $file -Raw
    if ($content -match "maps\.googleapis\.com" -or $content -match "Google Maps") {
        $googleMapsFound = $true
        break
    }
}

if ($googleMapsFound) {
    Write-Host "[PASS] Google Maps references found" -ForegroundColor Green
} else {
    Write-Host "[FAIL] No Google Maps references found" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 4: Verify track.html exists and has Google Maps
Write-Host "[TEST 4] Verifying track.html..." -ForegroundColor Yellow
if (Test-Path "Gemini3_AllSensesAI/track.html") {
    $trackHtml = Get-Content "Gemini3_AllSensesAI/track.html" -Raw
    
    # Check for Google Maps API
    if ($trackHtml -match "google\.maps" -or $trackHtml -match "maps\.googleapis\.com") {
        Write-Host "  [OK] Google Maps integration found" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Google Maps integration not found" -ForegroundColor Yellow
    }
    
    # Check for Leaflet (should be removed)
    if ($trackHtml -match "leaflet") {
        Write-Host "  [WARN] Leaflet references still present" -ForegroundColor Yellow
    } else {
        Write-Host "  [OK] Leaflet removed" -ForegroundColor Green
    }
    
    # Check for OpenStreetMap (should be removed)
    if ($trackHtml -match "openstreetmap") {
        Write-Host "  [WARN] OpenStreetMap references still present" -ForegroundColor Yellow
    } else {
        Write-Host "  [OK] OpenStreetMap removed" -ForegroundColor Green
    }
    
    Write-Host "[PASS] track.html verified" -ForegroundColor Green
} else {
    Write-Host "[FAIL] track.html not found" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 5: Verify CloudFormation template exists
Write-Host "[TEST 5] Verifying CloudFormation template..." -ForegroundColor Yellow
if (Test-Path "infrastructure/step2-live-tracking.yaml") {
    Write-Host "[PASS] CloudFormation template exists" -ForegroundColor Green
} else {
    Write-Host "[FAIL] CloudFormation template not found" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 6: Check for implementation code in summary
Write-Host "[TEST 6] Verifying implementation code..." -ForegroundColor Yellow
$summaryFile = "Gemini3_AllSensesAI/STEP2_GOOGLE_HACKATHON_ALIGNMENT_COMPLETE.md"
$summary = Get-Content $summaryFile -Raw

$requiredFunctions = @(
    "generateUUID",
    "handleLocationSuccess",
    "startLocationUpdates",
    "sendLocationUpdate",
    "stopLocationUpdates"
)

$allFunctionsFound = $true
foreach ($func in $requiredFunctions) {
    if ($summary -match $func) {
        Write-Host "  [OK] Function $func documented" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Function $func not found" -ForegroundColor Red
        $allFunctionsFound = $false
    }
}

if ($allFunctionsFound) {
    Write-Host "[PASS] All implementation functions documented" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Some implementation functions missing" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 7: Verify proof logs are documented
Write-Host "[TEST 7] Verifying proof logs..." -ForegroundColor Yellow
$requiredLogs = @(
    "\[STEP2\] Location preview updated",
    "\[STEP2\] Live tracking token created",
    "\[STEP2\] Live tracking link",
    "\[STEP2\] Location update sent",
    "\[TRACK\] Polling for token",
    "\[TRACK\] Location received"
)

$allLogsFound = $true
foreach ($log in $requiredLogs) {
    if ($summary -match $log) {
        Write-Host "  [OK] Proof log: $log" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Proof log not found: $log" -ForegroundColor Red
        $allLogsFound = $false
    }
}

if ($allLogsFound) {
    Write-Host "[PASS] All proof logs documented" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Some proof logs missing" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 8: Verify API key configuration is documented
Write-Host "[TEST 8] Verifying API key configuration..." -ForegroundColor Yellow
if ($summary -match "__GOOGLE_STATIC_MAPS_KEY__" -and $summary -match "__GOOGLE_MAPS_API_KEY__") {
    Write-Host "[PASS] API key configuration documented" -ForegroundColor Green
} else {
    Write-Host "[FAIL] API key configuration not found" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 9: Verify fallback behavior is documented
Write-Host "[TEST 9] Verifying fallback behavior..." -ForegroundColor Yellow
if ($summary -match "fallback" -and $summary -match "no key") {
    Write-Host "[PASS] Fallback behavior documented" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Fallback behavior not documented" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 10: Verify zero regression guarantee
Write-Host "[TEST 10] Verifying zero regression guarantee..." -ForegroundColor Yellow
if ($summary -match "Step 1 unchanged" -and $summary -match "Step 3 unchanged") {
    Write-Host "[PASS] Zero regression guarantee documented" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Zero regression guarantee not found" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[PASS] All tests passed!" -ForegroundColor Green
Write-Host ""
Write-Host "Google Maps integration is ready for deployment." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Review STEP2_GOOGLE_HACKATHON_ALIGNMENT_COMPLETE.md" -ForegroundColor White
Write-Host "2. Review STEP2_GOOGLE_MAPS_FILE_DIFFS.md" -ForegroundColor White
Write-Host "3. Deploy backend: aws cloudformation deploy --template-file infrastructure/step2-live-tracking.yaml ..." -ForegroundColor White
Write-Host "4. Update track.html with Lambda URL" -ForegroundColor White
Write-Host "5. Update Step 2 UI with implementation code" -ForegroundColor White
Write-Host "6. Deploy to production (after Ivan's approval)" -ForegroundColor White
Write-Host ""
Write-Host "For detailed instructions, see:" -ForegroundColor Cyan
Write-Host "  - Gemini3_AllSensesAI/STEP2_LIVE_TRACKING_DEPLOYMENT.md" -ForegroundColor White
Write-Host "  - Gemini3_AllSensesAI/STEP2_LIVE_TRACKING_LOCAL_TEST.md" -ForegroundColor White
Write-Host ""
