# Local Regression Test - Video SMS Evidence Capture RC1
# Purpose: Verify baseline production file unchanged and compute hashes

param(
    [Parameter(Mandatory=$false)]
    [string]$WorkspaceRoot = "."
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Local Regression Test - RC1" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Canonical hash file paths (relative to workspace root)
$Ckpt1HashFile = Join-Path $WorkspaceRoot "Gemini3_AllSensesAI/video/checkpoints/ckpt1-baseline-hash.txt"
$LocalHashFile = Join-Path $WorkspaceRoot "Gemini3_AllSensesAI/video/release/rc1/regression/known-baseline-hash.txt"

# Load known baseline hash from canonical source
$KNOWN_BASELINE_HASH = $null

if (Test-Path $Ckpt1HashFile) {
    Write-Host "Loading baseline hash from checkpoint 1 canonical file..." -ForegroundColor Cyan
    $KNOWN_BASELINE_HASH = (Get-Content $Ckpt1HashFile -Raw).Trim()
} elseif (Test-Path $LocalHashFile) {
    Write-Host "Loading baseline hash from local canonical file..." -ForegroundColor Cyan
    $KNOWN_BASELINE_HASH = (Get-Content $LocalHashFile -Raw).Trim()
} else {
    Write-Host "ERROR: Cannot locate authoritative ckpt1 baseline hash" -ForegroundColor Red
    Write-Host "Expected files:" -ForegroundColor Yellow
    Write-Host "  1. $Ckpt1HashFile" -ForegroundColor White
    Write-Host "  2. $LocalHashFile" -ForegroundColor White
    Write-Host "" -ForegroundColor White
    Write-Host "Action Required:" -ForegroundColor Yellow
    Write-Host "  Create ckpt1-baseline-hash.txt from checkpoint artifacts first" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "Loaded known baseline hash: $KNOWN_BASELINE_HASH" -ForegroundColor Green
Write-Host ""

# File paths
$BaselineFile = Join-Path $WorkspaceRoot "Gemini3_AllSensesAI/gemini3-guardian-production-sms.html"
$VideoFile = Join-Path $WorkspaceRoot "Gemini3_AllSensesAI/gemini3-guardian-production-sms-video.html"
$HashOutputFile = Join-Path $WorkspaceRoot "Gemini3_AllSensesAI/video/release/rc1/regression/hashes.txt"

Write-Host "[1/5] Validating file paths..." -ForegroundColor Yellow

# Check if baseline file exists
if (-not (Test-Path $BaselineFile)) {
    Write-Host "ERROR: Baseline file not found: $BaselineFile" -ForegroundColor Red
    exit 1
}

# Check if video file exists
if (-not (Test-Path $VideoFile)) {
    Write-Host "ERROR: Video file not found: $VideoFile" -ForegroundColor Red
    exit 1
}

Write-Host "  Baseline file: $BaselineFile" -ForegroundColor Green
Write-Host "  Video file: $VideoFile" -ForegroundColor Green
Write-Host ""

# Compute SHA256 hash for baseline file
Write-Host "[2/5] Computing baseline file hash..." -ForegroundColor Yellow
$BaselineHash = (Get-FileHash -Path $BaselineFile -Algorithm SHA256).Hash
Write-Host "  Baseline SHA256: $BaselineHash" -ForegroundColor Cyan
Write-Host ""

# Compute SHA256 hash for video file
Write-Host "[3/5] Computing video file hash..." -ForegroundColor Yellow
$VideoHash = (Get-FileHash -Path $VideoFile -Algorithm SHA256).Hash
Write-Host "  Video SHA256: $VideoHash" -ForegroundColor Cyan
Write-Host ""

# Verify baseline hash matches known checkpoint 1 hash
Write-Host "[4/5] Verifying baseline hash..." -ForegroundColor Yellow
Write-Host "  Known hash (ckpt1): $KNOWN_BASELINE_HASH" -ForegroundColor Cyan
Write-Host "  Current hash:       $BaselineHash" -ForegroundColor Cyan

if ($BaselineHash -eq $KNOWN_BASELINE_HASH) {
    Write-Host "  [PASS] Baseline hash matches checkpoint 1" -ForegroundColor Green
    $BaselineVerified = $true
} else {
    Write-Host "  [FAIL] Baseline hash MISMATCH!" -ForegroundColor Red
    Write-Host "  ERROR: Production baseline file has been modified!" -ForegroundColor Red
    Write-Host "  This is a CRITICAL regression - baseline must remain unchanged" -ForegroundColor Red
    $BaselineVerified = $false
}
Write-Host ""

# Write hashes to output file
Write-Host "[5/5] Writing hashes to file..." -ForegroundColor Yellow
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$HashContent = @"
# Regression Test Hashes - RC1
# Generated: $Timestamp

## Baseline Production File
File: gemini3-guardian-production-sms.html
SHA256: $BaselineHash
Known Hash (ckpt1): $KNOWN_BASELINE_HASH
Verified: $BaselineVerified

## Video Variant File
File: gemini3-guardian-production-sms-video.html
SHA256: $VideoHash

## Verification Status
Baseline Verified: $BaselineVerified
Baseline Unchanged: $($BaselineHash -eq $KNOWN_BASELINE_HASH)

"@

$HashContent | Out-File -FilePath $HashOutputFile -Encoding UTF8
Write-Host "  Hashes written to: $HashOutputFile" -ForegroundColor Green
Write-Host ""

# Print summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Regression Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($BaselineVerified) {
    Write-Host "Status: PASS" -ForegroundColor Green
    Write-Host "Baseline: UNCHANGED (verified against checkpoint 1)" -ForegroundColor Green
    Write-Host "Video Variant: READY FOR TESTING" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Review hashes.txt for verification" -ForegroundColor White
    Write-Host "2. Execute manual regression tests (REGRESSION_CHECKLIST.md)" -ForegroundColor White
    Write-Host "3. Run deployment regression script (run-regression-deploy.ps1)" -ForegroundColor White
    Write-Host ""
    exit 0
} else {
    Write-Host "Status: FAIL" -ForegroundColor Red
    Write-Host "Baseline: MODIFIED (does not match checkpoint 1)" -ForegroundColor Red
    Write-Host "Video Variant: NOT SAFE TO DEPLOY" -ForegroundColor Red
    Write-Host ""
    Write-Host "Action Required:" -ForegroundColor Yellow
    Write-Host "1. Investigate why baseline file was modified" -ForegroundColor White
    Write-Host "2. Restore baseline from checkpoint 1 backup" -ForegroundColor White
    Write-Host "3. Re-run regression test" -ForegroundColor White
    Write-Host ""
    exit 1
}
