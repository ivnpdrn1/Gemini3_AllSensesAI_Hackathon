# Verify Yandex Maps Elimination from Step 2 UI
# This script verifies that all Yandex Maps references have been removed

Write-Host "=== Yandex Maps Elimination Verification ===" -ForegroundColor Cyan
Write-Host ""

$htmlFile = "Gemini3_AllSensesAI/gemini3-guardian-production-sms-video-REBUILT.html"

# Test 1: Check for Yandex string presence
Write-Host "[TEST 1] Checking for 'yandex' string in HTML..." -ForegroundColor Yellow
$yandexCount = (Select-String -Path $htmlFile -Pattern "yandex" -AllMatches -CaseSensitive:$false).Count

if ($yandexCount -eq 0) {
    Write-Host "[PASS] No 'yandex' strings found" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Found $yandexCount 'yandex' references" -ForegroundColor Red
    Select-String -Path $htmlFile -Pattern "yandex" -CaseSensitive:$false | ForEach-Object {
        Write-Host "  Line $($_.LineNumber): $($_.Line.Trim())" -ForegroundColor Red
    }
}

# Test 2: Check for Google Maps implementation
Write-Host ""
Write-Host "[TEST 2] Checking for Google Maps implementation..." -ForegroundColor Yellow
$googleMapsCount = (Select-String -Path $htmlFile -Pattern "maps\.google" -AllMatches).Count
$googleApiCount = (Select-String -Path $htmlFile -Pattern "maps\.googleapis\.com" -AllMatches).Count

if ($googleMapsCount -gt 0 -or $googleApiCount -gt 0) {
    Write-Host "[PASS] Google Maps implementation found ($googleMapsCount links, $googleApiCount API calls)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] No Google Maps implementation found" -ForegroundColor Red
}

# Test 3: Check for configurable key support
Write-Host ""
Write-Host "[TEST 3] Checking for configurable API key support..." -ForegroundColor Yellow
$keyConfigCount = (Select-String -Path $htmlFile -Pattern "__GOOGLE_STATIC_MAPS_KEY__" -AllMatches).Count

if ($keyConfigCount -gt 0) {
    Write-Host "[PASS] Configurable API key support found ($keyConfigCount references)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] No configurable API key support found" -ForegroundColor Red
}

# Test 4: Check for console logging
Write-Host ""
Write-Host "[TEST 4] Checking for Google Maps console logging..." -ForegroundColor Yellow
$loggingCount = (Select-String -Path $htmlFile -Pattern "\[STEP[24]\]\[MAP\].*google" -AllMatches).Count

if ($loggingCount -gt 0) {
    Write-Host "[PASS] Google Maps logging found ($loggingCount log statements)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] No Google Maps logging found" -ForegroundColor Red
}

# Test 5: Check for both Step 2 and Step 4 implementations
Write-Host ""
Write-Host "[TEST 5] Checking for Step 2 and Step 4 map implementations..." -ForegroundColor Yellow
$step2MapCount = (Select-String -Path $htmlFile -Pattern "function updateLocationPreview" -AllMatches).Count
$step4MapCount = (Select-String -Path $htmlFile -Pattern "function triggerEmergencyAlert" -AllMatches).Count

if ($step2MapCount -gt 0 -and $step4MapCount -gt 0) {
    Write-Host "[PASS] Both Step 2 and Step 4 map implementations found" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Missing map implementations (Step 2: $step2MapCount, Step 4: $step4MapCount)" -ForegroundColor Red
}

# Summary
Write-Host ""
Write-Host "=== Verification Summary ===" -ForegroundColor Cyan
Write-Host "File: $htmlFile"
Write-Host "Yandex references: $yandexCount (should be 0)"
Write-Host "Google Maps links: $googleMapsCount"
Write-Host "Google API calls: $googleApiCount"
Write-Host "Configurable key support: $keyConfigCount"
Write-Host ""

if ($yandexCount -eq 0 -and ($googleMapsCount -gt 0 -or $googleApiCount -gt 0) -and $keyConfigCount -gt 0) {
    Write-Host "[SUCCESS] Yandex Maps successfully eliminated and replaced with Google Maps" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[FAILURE] Verification failed - see errors above" -ForegroundColor Red
    exit 1
}
