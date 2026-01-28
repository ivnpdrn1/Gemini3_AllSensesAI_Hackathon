#!/usr/bin/env pwsh
# Verify Jury-Ready VIDEO Build Deployment
# Build ID: GEMINI3-JURY-READY-VIDEO-20260128-v1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$BUILD_ID = "GEMINI3-JURY-READY-VIDEO-20260128-v1"
$CLOUDFRONT_URL = "https://dfc8ght8abwqc.cloudfront.net"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verifying Jury-Ready VIDEO Build" -ForegroundColor Cyan
Write-Host "Build ID: $BUILD_ID" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Fetch the deployed page
Write-Host "Fetching deployed page..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri $CLOUDFRONT_URL -UseBasicParsing
    $html = $response.Content
    Write-Host "[OK] Page fetched successfully" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to fetch page: $_" -ForegroundColor Red
    exit 1
}

$passed = 0
$failed = 0

# Test 1: Build ID in top stamp
Write-Host ""
Write-Host "Test 1: Build ID in top stamp" -ForegroundColor Cyan
if ($html -match "Build: $BUILD_ID") {
    Write-Host "  [PASS] Build ID found in top stamp" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  [FAIL] Build ID not found in top stamp" -ForegroundColor Red
    $failed++
}

# Test 2: Build ID in Runtime Health Check
Write-Host ""
Write-Host "Test 2: Build ID in Runtime Health Check" -ForegroundColor Cyan
if ($html -match "Loaded Build ID.*$BUILD_ID") {
    Write-Host "  [PASS] Build ID found in Runtime Health Check" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  [FAIL] Build ID not found in Runtime Health Check" -ForegroundColor Red
    $failed++
}

# Test 3: Vision Panel exists
Write-Host ""
Write-Host "Test 3: Vision Panel exists" -ForegroundColor Cyan
if ($html -match 'id="visionContextPanel"') {
    Write-Host "  [PASS] Vision Panel found" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  [FAIL] Vision Panel not found" -ForegroundColor Red
    $failed++
}

# Test 4: Vision Panel title
Write-Host ""
Write-Host "Test 4: Vision Panel title" -ForegroundColor Cyan
if ($html -match 'Visual Context \(Gemini Vision\)') {
    Write-Host "  [PASS] Vision Panel title correct" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  [FAIL] Vision Panel title not found" -ForegroundColor Red
    $failed++
}

# Test 5: 3 frame placeholders
Write-Host ""
Write-Host "Test 5: 3 frame placeholders" -ForegroundColor Cyan
$frameCount = ([regex]::Matches($html, 'Frame \d<br>not captured')).Count
if ($frameCount -eq 3) {
    Write-Host "  [PASS] 3 frame placeholders found" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  [FAIL] Expected 3 frame placeholders, found $frameCount" -ForegroundColor Red
    $failed++
}

# Test 6: Capture policy text
Write-Host ""
Write-Host "Test 6: Capture policy text" -ForegroundColor Cyan
if ($html -match 'Captures 1') {
    Write-Host "  [PASS] Capture policy text found" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  [FAIL] Capture policy text not found" -ForegroundColor Red
    $failed++
}

# Test 7: Vision status badge
Write-Host ""
Write-Host "Test 7: Vision status badge" -ForegroundColor Cyan
if ($html -match 'id="visionStatusBadge"') {
    Write-Host "  [PASS] Vision status badge found" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  [FAIL] Vision status badge not found" -ForegroundColor Red
    $failed++
}

# Test 8: Step 1 button is type="button"
Write-Host ""
Write-Host "Test 8: Step 1 button (baseline)" -ForegroundColor Cyan
if ($html -match 'type="button".*onclick="completeStep1\(\)"') {
    Write-Host "  [PASS] Step 1 button is type='button'" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  [FAIL] Step 1 button regression" -ForegroundColor Red
    $failed++
}

# Test 9: All 8 SMS preview fields (baseline)
Write-Host ""
Write-Host "Test 9: SMS preview fields (baseline)" -ForegroundColor Cyan
$smsFields = @('sms-victim', 'sms-risk', 'sms-recommendation', 'sms-message', 
               'sms-location', 'sms-map', 'sms-time', 'sms-action')
$missingSmsFields = @()
foreach ($field in $smsFields) {
    if ($html -notmatch "id=`"$field`"") {
        $missingSmsFields += $field
    }
}
if ($missingSmsFields.Count -eq 0) {
    Write-Host "  [PASS] All 8 SMS preview fields present" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  [FAIL] Missing SMS fields: $($missingSmsFields -join ', ')" -ForegroundColor Red
    $failed++
}

# Test 10: Configurable keywords UI (baseline)
Write-Host ""
Write-Host "Test 10: Configurable keywords UI (baseline)" -ForegroundColor Cyan
if ($html -match 'class="keywords-config"') {
    Write-Host "  [PASS] Configurable keywords UI present" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  [FAIL] Configurable keywords UI missing" -ForegroundColor Red
    $failed++
}

# Test 11: Required baseline functions
Write-Host ""
Write-Host "Test 11: Required baseline functions" -ForegroundColor Cyan
$requiredFunctions = @('composeAlertPayload', 'composeAlertSms', 'renderSmsPreviewFields', 
                       'updateSmsPreview', 'completeStep1')
$missingFunctions = @()
foreach ($func in $requiredFunctions) {
    if ($html -notmatch "function $func\(") {
        $missingFunctions += $func
    }
}
if ($missingFunctions.Count -eq 0) {
    Write-Host "  [PASS] All required baseline functions present" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  [FAIL] Missing functions: $($missingFunctions -join ', ')" -ForegroundColor Red
    $failed++
}

# Test 12: Vision proof logging functions
Write-Host ""
Write-Host "Test 12: Vision proof logging functions" -ForegroundColor Cyan
if ($html -match 'function addVisionProofLog\(' -and $html -match 'function updateVisionStatus\(') {
    Write-Host "  [PASS] Vision proof logging functions present" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  [FAIL] Vision proof logging functions missing" -ForegroundColor Red
    $failed++
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VERIFICATION SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Tests: $($passed + $failed)" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($failed -eq 0) {
    Write-Host "ALL TESTS PASSED" -ForegroundColor Green
    Write-Host ""
    Write-Host "Deployment verified successfully!" -ForegroundColor Green
    Write-Host "   Build ID: $BUILD_ID" -ForegroundColor White
    Write-Host "   CloudFront URL: $CLOUDFRONT_URL" -ForegroundColor White
    Write-Host ""
    Write-Host "What's New:" -ForegroundColor Cyan
    Write-Host "  [+] Vision Panel with 3 frame placeholders" -ForegroundColor Green
    Write-Host "  [+] Vision status badge" -ForegroundColor Green
    Write-Host "  [+] Capture policy text" -ForegroundColor Green
    Write-Host "  [+] Vision proof logs" -ForegroundColor Green
    Write-Host ""
    Write-Host "Baseline Preserved:" -ForegroundColor Cyan
    Write-Host "  [OK] Step 1 button fix" -ForegroundColor Green
    Write-Host "  [OK] Step 5 SMS preview (8 fields)" -ForegroundColor Green
    Write-Host "  [OK] Configurable keywords UI" -ForegroundColor Green
    Write-Host "  [OK] Build Identity proof (2 locations)" -ForegroundColor Green
    Write-Host ""
    exit 0
} else {
    Write-Host "VERIFICATION FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Some tests failed. Review the output above." -ForegroundColor Yellow
    Write-Host "If CloudFront is still propagating, wait 2-3 minutes and retry." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
