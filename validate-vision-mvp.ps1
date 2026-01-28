# Quick Vision MVP Validation
Write-Host "Vision MVP Validation" -ForegroundColor Cyan
Write-Host "Build: GEMINI3-VISION-MVP-20260127" -ForegroundColor Cyan
Write-Host ""

$file = "Gemini3_AllSensesAI/gemini3-guardian-vision-mvp.html"

if (Test-Path $file) {
    Write-Host "[OK] File exists: $file" -ForegroundColor Green
    
    $content = Get-Content $file -Raw
    
    # Check for Vision panel
    if ($content -match "vision-context-panel") {
        Write-Host "[OK] Vision panel HTML found" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Vision panel HTML missing" -ForegroundColor Red
    }
    
    # Check for VisionContextController
    if ($content -match "class VisionContextController") {
        Write-Host "[OK] VisionContextController class found" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] VisionContextController class missing" -ForegroundColor Red
    }
    
    # Check for build stamp
    if ($content -match "GEMINI3-VISION-MVP-20260127") {
        Write-Host "[OK] Build stamp correct" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Build stamp incorrect" -ForegroundColor Red
    }
    
    # Check for vision activation
    if ($content -match "visionContextController.activateOnEmergency") {
        Write-Host "[OK] Vision activation integrated" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Vision activation missing" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "[SUCCESS] All checks passed!" -ForegroundColor Green
} else {
    Write-Host "[FAIL] File not found: $file" -ForegroundColor Red
}
