# Verify Victim Name Enhancements
# Quick verification script to check all enhancements were applied

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Victim Name Enhancements Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$FILE = "Gemini3_AllSensesAI/gemini3-guardian-victim-name-enhanced.html"

if (-not (Test-Path $FILE)) {
    Write-Host "ERROR: Enhanced file not found: $FILE" -ForegroundColor Red
    exit 1
}

Write-Host "Checking file: $FILE" -ForegroundColor Green
Write-Host ""

$content = Get-Content $FILE -Raw

# Check 1: Build stamp updated
Write-Host "[1/8] Checking build stamp..." -ForegroundColor Yellow
if ($content -match "GEMINI3-VICTIM-NAME-ENHANCED-20260128") {
    Write-Host "  ✓ Build stamp updated" -ForegroundColor Green
} else {
    Write-Host "  ✗ Build stamp not updated" -ForegroundColor Red
    exit 1
}

# Check 2: SMS message uses "Victim:" instead of "Contact:"
Write-Host "[2/8] Checking SMS message format..." -ForegroundColor Yellow
if ($content -match "Victim: \$\{payload\.victimName\}") {
    Write-Host "  ✓ SMS uses 'Victim:' label" -ForegroundColor Green
} else {
    Write-Host "  ✗ SMS still uses 'Contact:' label" -ForegroundColor Red
    exit 1
}

# Check 3: Victim name normalization added
Write-Host "[3/8] Checking victim name normalization..." -ForegroundColor Yellow
if ($content -match "const victimName = \(payload\.victimName \|\| ''\)\.trim\(\) \|\| 'Unknown User'") {
    Write-Host "  ✓ Victim name normalization added" -ForegroundColor Green
} else {
    Write-Host "  ✗ Victim name normalization missing" -ForegroundColor Red
    exit 1
}

# Check 4: Victim name metadata display
Write-Host "[4/8] Checking victim name metadata display..." -ForegroundColor Yellow
if ($content -match 'id="smsPreviewVictimName"') {
    Write-Host "  ✓ Victim name metadata display added" -ForegroundColor Green
} else {
    Write-Host "  ✗ Victim name metadata display missing" -ForegroundColor Red
    exit 1
}

# Check 5: Victim name checklist item
Write-Host "[5/8] Checking victim name checklist item..." -ForegroundColor Yellow
if ($content -match 'id="smsCheckVictimName"') {
    Write-Host "  ✓ Victim name checklist item added" -ForegroundColor Green
} else {
    Write-Host "  ✗ Victim name checklist item missing" -ForegroundColor Red
    exit 1
}

# Check 6: Fallback warning display
Write-Host "[6/8] Checking fallback warning display..." -ForegroundColor Yellow
if ($content -match "Using fallback: Unknown User") {
    Write-Host "  ✓ Fallback warning display added" -ForegroundColor Green
} else {
    Write-Host "  ✗ Fallback warning display missing" -ForegroundColor Red
    exit 1
}

# Check 7: Step 1 warning proof log
Write-Host "[7/8] Checking Step 1 warning proof log..." -ForegroundColor Yellow
if ($content -match "\[STEP1\]\[WARNING\] Victim name empty - will use fallback") {
    Write-Host "  ✓ Step 1 warning proof log added" -ForegroundColor Green
} else {
    Write-Host "  ✗ Step 1 warning proof log missing" -ForegroundColor Red
    exit 1
}

# Check 8: Step 5 SMS composition proof log
Write-Host "[8/8] Checking Step 5 SMS composition proof log..." -ForegroundColor Yellow
if ($content -match "\[STEP5\] SMS composed for:") {
    Write-Host "  ✓ Step 5 SMS composition proof log added" -ForegroundColor Green
} else {
    Write-Host "  ✗ Step 5 SMS composition proof log missing" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "All Checks Passed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "File is ready for deployment:" -ForegroundColor Cyan
Write-Host "  $FILE" -ForegroundColor White
Write-Host ""
Write-Host "Deploy using:" -ForegroundColor Yellow
Write-Host "  .\Gemini3_AllSensesAI\deployment\deploy-victim-name-enhanced.ps1" -ForegroundColor White
Write-Host ""
