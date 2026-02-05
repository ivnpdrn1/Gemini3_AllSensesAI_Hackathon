# Deployment Regression Test - Video SMS Evidence Capture RC1
# Purpose: Print test URLs and proof collection commands for manual testing

param(
    [Parameter(Mandatory=$true)]
    [string]$CloudFrontDomain,
    
    [Parameter(Mandatory=$false)]
    [string]$BaselinePath = "index.html",
    
    [Parameter(Mandatory=$false)]
    [string]$VideoPath = "video/index.html"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Regression Test - RC1" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Construct URLs
$BaselineURL = "https://$CloudFrontDomain/$BaselinePath"
$VideoURL = "https://$CloudFrontDomain/$VideoPath"

Write-Host "Test URLs:" -ForegroundColor Yellow
Write-Host "  Baseline Production: $BaselineURL" -ForegroundColor Cyan
Write-Host "  Video Variant:       $VideoURL" -ForegroundColor Cyan
Write-Host ""

# Print test instructions
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Manual Testing Instructions" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 1: Open Chrome DevTools" -ForegroundColor Yellow
Write-Host "  1. Open Chrome browser" -ForegroundColor White
Write-Host "  2. Press F12 to open DevTools" -ForegroundColor White
Write-Host "  3. Go to Console tab" -ForegroundColor White
Write-Host "  4. Go to Network tab" -ForegroundColor White
Write-Host "  5. Clear network log (trash icon)" -ForegroundColor White
Write-Host ""

Write-Host "Step 2: Test Baseline Production (Regression Check)" -ForegroundColor Yellow
Write-Host "  URL: $BaselineURL" -ForegroundColor Cyan
Write-Host "  1. Load URL in browser" -ForegroundColor White
Write-Host "  2. Wait 5 seconds" -ForegroundColor White
Write-Host "  3. Verify no console errors" -ForegroundColor White
Write-Host "  4. Verify only 1 network request (HTML file)" -ForegroundColor White
Write-Host "  5. Complete Steps 1-3 and send SMS" -ForegroundColor White
Write-Host "  6. Verify SMS sends successfully" -ForegroundColor White
Write-Host ""

Write-Host "Step 3: Test Video Variant (New Functionality)" -ForegroundColor Yellow
Write-Host "  URL: $VideoURL" -ForegroundColor Cyan
Write-Host "  1. Load URL in browser" -ForegroundColor White
Write-Host "  2. Wait 5 seconds" -ForegroundColor White
Write-Host "  3. Verify no console errors" -ForegroundColor White
Write-Host "  4. Verify only 1 network request (HTML file)" -ForegroundColor White
Write-Host "  5. Complete Steps 1-3" -ForegroundColor White
Write-Host "  6. Capture video in Step 4 (allow camera access)" -ForegroundColor White
Write-Host "  7. Send SMS with video" -ForegroundColor White
Write-Host "  8. Verify SMS includes video link" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Proof Collection Commands" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Console Logs to Copy:" -ForegroundColor Yellow
Write-Host "  1. Right-click in Console tab" -ForegroundColor White
Write-Host "  2. Select 'Save as...' or copy all logs" -ForegroundColor White
Write-Host "  3. Paste into PROOF_BUNDLE.md" -ForegroundColor White
Write-Host ""

Write-Host "Network Request Payload:" -ForegroundColor Yellow
Write-Host "  1. Go to Network tab" -ForegroundColor White
Write-Host "  2. Find POST request to Lambda URL" -ForegroundColor White
Write-Host "  3. Click on request" -ForegroundColor White
Write-Host "  4. Go to 'Payload' tab" -ForegroundColor White
Write-Host "  5. Copy JSON payload" -ForegroundColor White
Write-Host "  6. Paste into PROOF_BUNDLE.md" -ForegroundColor White
Write-Host ""

Write-Host "Network Response:" -ForegroundColor Yellow
Write-Host "  1. In same POST request" -ForegroundColor White
Write-Host "  2. Go to 'Response' tab" -ForegroundColor White
Write-Host "  3. Copy JSON response" -ForegroundColor White
Write-Host "  4. Paste into PROOF_BUNDLE.md" -ForegroundColor White
Write-Host ""

Write-Host "Screenshots to Capture:" -ForegroundColor Yellow
Write-Host "  1. Page load (no console errors)" -ForegroundColor White
Write-Host "  2. Network tab (only HTML request)" -ForegroundColor White
Write-Host "  3. Step 1 button (DevTools Elements tab)" -ForegroundColor White
Write-Host "  4. Video panel in Step 4" -ForegroundColor White
Write-Host "  5. SMS payload with videoEvidenceUrl" -ForegroundColor White
Write-Host ""

# Append test run header to PROOF_BUNDLE.md
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$ProofBundlePath = "Gemini3_AllSensesAI/video/release/rc1/PROOF_BUNDLE.md"

if (Test-Path $ProofBundlePath) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Updating PROOF_BUNDLE.md" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $TestRunHeader = @"

---

# Test Run: $Timestamp

**Baseline URL**: $BaselineURL  
**Video URL**: $VideoURL  
**Tester**: [FILL: Your Name]  
**Browser**: [FILL: Chrome + Version]  
**Status**: [FILL: IN PROGRESS/COMPLETE]

## Test Results
[FILL: Paste test results here]

---

"@
    
    Add-Content -Path $ProofBundlePath -Value $TestRunHeader
    Write-Host "  Test run header appended to PROOF_BUNDLE.md" -ForegroundColor Green
    Write-Host "  Timestamp: $Timestamp" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "  WARNING: PROOF_BUNDLE.md not found at $ProofBundlePath" -ForegroundColor Yellow
    Write-Host ""
}

# Print next steps
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Execute manual tests using URLs above" -ForegroundColor White
Write-Host "2. Collect proof (console logs, network requests, screenshots)" -ForegroundColor White
Write-Host "3. Fill PROOF_BUNDLE.md with collected proof" -ForegroundColor White
Write-Host "4. Review REGRESSION_CHECKLIST.md and mark tests as passed/failed" -ForegroundColor White
Write-Host "5. If all tests pass, proceed to production deployment" -ForegroundColor White
Write-Host "6. If any test fails, execute rollback script" -ForegroundColor White
Write-Host ""

Write-Host "Deployment regression test instructions printed successfully!" -ForegroundColor Green
Write-Host ""
