#!/usr/bin/env pwsh
# Verify Emergency Triggered Warning UI Deployment
# Build: GEMINI3-EMERGENCY-UI-20260127

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Emergency UI Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$CLOUDFRONT_URL = "https://d3pbubsw4or36l.cloudfront.net/gemini3-guardian-ux-enhanced.html"

Write-Host "[CHECK 1] Fetching deployed file..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri $CLOUDFRONT_URL -UseBasicParsing
    $content = $response.Content
    
    Write-Host "  [OK] File fetched successfully" -ForegroundColor Green
    Write-Host "  Size: $($content.Length) bytes" -ForegroundColor Gray
} catch {
    Write-Host "  [ERROR] Failed to fetch file: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[CHECK 2] Verifying emergency features..." -ForegroundColor Yellow

$checks = @(
    @{ Name = "Emergency Banner CSS"; Pattern = "\.emergency-banner"; Required = $true },
    @{ Name = "Emergency Modal CSS"; Pattern = "\.emergency-modal"; Required = $true },
    @{ Name = "Emergency Badge CSS"; Pattern = "\.mic-status-badge\.emergency-detected"; Required = $true },
    @{ Name = "Emergency Pulse Animation"; Pattern = "@keyframes emergencyPulse"; Required = $true },
    @{ Name = "Modal Slide Animation"; Pattern = "@keyframes modalSlideIn"; Required = $true },
    @{ Name = "Badge Pulse Animation"; Pattern = "@keyframes badgePulse"; Required = $true },
    @{ Name = "Emergency Banner HTML"; Pattern = 'id="emergencyBanner"'; Required = $true },
    @{ Name = "Emergency Modal HTML"; Pattern = 'id="emergencyModal"'; Required = $true },
    @{ Name = "checkForEmergencyKeywords Function"; Pattern = "function checkForEmergencyKeywords"; Required = $true },
    @{ Name = "triggerEmergencyWorkflow Function"; Pattern = "function triggerEmergencyWorkflow"; Required = $true },
    @{ Name = "showEmergencyBanner Function"; Pattern = "function showEmergencyBanner"; Required = $true },
    @{ Name = "showEmergencyModal Function"; Pattern = "function showEmergencyModal"; Required = $true },
    @{ Name = "closeEmergencyModal Function"; Pattern = "function closeEmergencyModal"; Required = $true },
    @{ Name = "Emergency Keywords Array"; Pattern = "emergencyKeywords = \["; Required = $true },
    @{ Name = "STEP3_EMERGENCY_TRIGGERED State"; Pattern = "STEP3_EMERGENCY_TRIGGERED"; Required = $true },
    @{ Name = "Emergency Trigger Proof Log"; Pattern = "\[TRIGGER\] Emergency keyword detected"; Required = $true },
    @{ Name = "Build Stamp"; Pattern = "GEMINI3-UX-ENHANCED-20260127"; Required = $true }
)

$passed = 0
$failed = 0

foreach ($check in $checks) {
    if ($content -match [regex]::Escape($check.Pattern)) {
        Write-Host "  [OK] $($check.Name)" -ForegroundColor Green
        $passed++
    } else {
        if ($check.Required) {
            Write-Host "  [FAIL] $($check.Name)" -ForegroundColor Red
            $failed++
        } else {
            Write-Host "  [SKIP] $($check.Name)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "[CHECK 3] Feature verification summary..." -ForegroundColor Yellow
Write-Host "  Passed: $passed" -ForegroundColor Green
Write-Host "  Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

if ($failed -eq 0) {
    Write-Host "VERIFICATION PASSED" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "All emergency UI features verified!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Open: $CLOUDFRONT_URL" -ForegroundColor White
    Write-Host "  2. Complete Steps 1 & 2" -ForegroundColor White
    Write-Host "  3. Start Voice Detection (Step 3)" -ForegroundColor White
    Write-Host "  4. Say: 'it is emergency' or 'help'" -ForegroundColor White
    Write-Host "  5. Verify emergency UI appears" -ForegroundColor White
    Write-Host ""
    Write-Host "Expected Results:" -ForegroundColor Yellow
    Write-Host "  - Red emergency banner at top" -ForegroundColor Gray
    Write-Host "  - Step 3 badge: 'EMERGENCY DETECTED'" -ForegroundColor Gray
    Write-Host "  - Modal overlay with confirmation" -ForegroundColor Gray
    Write-Host "  - Proof log shows trigger events" -ForegroundColor Gray
    Write-Host "  - Auto-advance to Step 4" -ForegroundColor Gray
    Write-Host ""
    exit 0
} else {
    Write-Host "VERIFICATION FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Some features are missing. Please check deployment." -ForegroundColor Red
    Write-Host ""
    exit 1
}
