# STEP 1 SYNTAX FIX VERIFICATION
# Verifies the hotfix was applied correctly

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STEP 1 SYNTAX FIX VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$SOURCE_FILE = "Gemini3_AllSensesAI/index.html"
$EXPECTED_BUILD = "GEMINI3-GUARDIAN-SMS-VIDEO-20260131-v3-HOTFIX"

Write-Host "[1/5] Checking file exists..." -ForegroundColor Yellow
if (-not (Test-Path $SOURCE_FILE)) {
    Write-Host "  FAIL: File not found" -ForegroundColor Red
    exit 1
}
Write-Host "  PASS: File exists" -ForegroundColor Green

Write-Host ""
Write-Host "[2/5] Checking Build ID..." -ForegroundColor Yellow
$content = Get-Content $SOURCE_FILE -Raw
if ($content -match $EXPECTED_BUILD) {
    Write-Host "  PASS: Build ID updated to $EXPECTED_BUILD" -ForegroundColor Green
} else {
    Write-Host "  FAIL: Build ID not found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[3/5] Checking updateMicStatus calls have parameters..." -ForegroundColor Yellow
$badCalls = Select-String -Path $SOURCE_FILE -Pattern "updateMicStatus;" -AllMatches
if ($badCalls) {
    Write-Host "  FAIL: Found updateMicStatus calls without parameters:" -ForegroundColor Red
    $badCalls | ForEach-Object { Write-Host "    Line $($_.LineNumber): $($_.Line.Trim())" -ForegroundColor Red }
    exit 1
} else {
    Write-Host "  PASS: All updateMicStatus calls have parameters" -ForegroundColor Green
}

Write-Host ""
Write-Host "[4/5] Checking runtime proof exists..." -ForegroundColor Yellow
if ($content -match '\[BOOT\] JS loaded; completeStep1 type') {
    Write-Host "  PASS: Runtime proof added" -ForegroundColor Green
} else {
    Write-Host "  FAIL: Runtime proof not found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[5/5] Checking backup was created..." -ForegroundColor Yellow
$backups = Get-ChildItem "Gemini3_AllSensesAI/index.html.bak.*" -ErrorAction SilentlyContinue
if ($backups) {
    $latest = $backups | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    Write-Host "  PASS: Backup exists: $($latest.Name)" -ForegroundColor Green
} else {
    Write-Host "  WARN: No backup found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "ALL CHECKS PASSED" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Test locally by opening $SOURCE_FILE in Chrome" -ForegroundColor White
Write-Host "2. Open browser console (F12)" -ForegroundColor White
Write-Host "3. Verify console shows: [BOOT] JS loaded; completeStep1 type = function" -ForegroundColor White
Write-Host "4. Click 'Complete Step 1' and verify it works" -ForegroundColor White
Write-Host "5. If all tests pass, run: ./Gemini3_AllSensesAI/deployment/deploy-step1-syntax-hotfix.ps1" -ForegroundColor White
Write-Host ""
