# Final Deployment Verification
# Checks if completeStep1 function is accessible in deployed version

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Final Deployment Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$CLOUDFRONT_URL = "https://dfc8ght8abwqc.cloudfront.net"

Write-Host "[1/4] Fetching deployed version..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri $CLOUDFRONT_URL -UseBasicParsing -Headers @{
        "Cache-Control" = "no-cache"
        "Pragma" = "no-cache"
    }
    
    $content = $response.Content
    Write-Host "   Fetched: $($content.Length) bytes" -ForegroundColor Green
} catch {
    Write-Host "   Failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/4] Checking for completeStep1 function..." -ForegroundColor Cyan

if ($content -match 'function completeStep1\(\)') {
    Write-Host "   FOUND: completeStep1 function definition" -ForegroundColor Green
} else {
    Write-Host "   NOT FOUND: completeStep1 function" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[3/4] Checking for onclick handler..." -ForegroundColor Cyan

if ($content -match 'onclick="completeStep1\(\)"') {
    Write-Host "   FOUND: Button onclick attribute" -ForegroundColor Green
} else {
    Write-Host "   NOT FOUND: Button onclick attribute" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[4/4] Checking for corruption..." -ForegroundColor Cyan

$corruptionFound = $false

if ($content -match 'step1StatInternational') {
    Write-Host "   CORRUPTION: step1StatInternational found" -ForegroundColor Red
    $corruptionFound = $true
}

if ($content -match 'Internationaling') {
    Write-Host "   CORRUPTION: Internationaling found" -ForegroundColor Red
    $corruptionFound = $true
}

if (-not $corruptionFound) {
    Write-Host "   No corruption detected" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Verification Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

if ($corruptionFound) {
    Write-Host "Status: FAILED - Corruption detected" -ForegroundColor Red
    Write-Host ""
    Write-Host "The deployed version still has corruption." -ForegroundColor Yellow
    Write-Host "This should not happen after a fresh deployment." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host ""
    Write-Host "The deployed version appears correct:" -ForegroundColor White
    Write-Host "   - completeStep1 function exists" -ForegroundColor Gray
    Write-Host "   - Button has onclick handler" -ForegroundColor Gray
    Write-Host "   - No corruption detected" -ForegroundColor Gray
    Write-Host ""
    Write-Host "User Action Required:" -ForegroundColor Yellow
    Write-Host "   1. Open: https://dfc8ght8abwqc.cloudfront.net" -ForegroundColor White
    Write-Host "   2. Hard refresh: Ctrl+Shift+R (or Cmd+Shift+R on Mac)" -ForegroundColor White
    Write-Host "   3. Open browser console (F12)" -ForegroundColor White
    Write-Host "   4. Paste and run the diagnostic:" -ForegroundColor White
    Write-Host ""
    Write-Host "      Copy from: COPY_PASTE_STEP1_DIAGNOSTIC.js" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   5. Verify output shows:" -ForegroundColor White
    Write-Host "      - Type: function" -ForegroundColor Gray
    Write-Host "      - Exists: YES" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   6. Click 'Complete Step 1' button to test" -ForegroundColor White
    Write-Host ""
}
