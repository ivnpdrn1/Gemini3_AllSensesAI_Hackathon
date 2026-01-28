# Verify Vision Panel in Deployed File
# Build: GEMINI3-VISION-VIDEO-FIX-20260127

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Vision Panel Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$UI_FILE = "ui/index.html"

if (-not (Test-Path $UI_FILE)) {
    Write-Host "ERROR: $UI_FILE not found!" -ForegroundColor Red
    exit 1
}

Write-Host "Reading $UI_FILE..." -ForegroundColor Yellow
$content = Get-Content $UI_FILE -Raw

Write-Host ""
Write-Host "Verification Checks:" -ForegroundColor Cyan
Write-Host ""

# Check 1: Vision panel exists
Write-Host "[1] Vision Context Panel..." -NoNewline
if ($content -match "vision-context-panel") {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $failed = $true
}

# Check 2: Panel title with VIDEO
Write-Host "[2] Panel Title (mentions VIDEO)..." -NoNewline
if ($content -match "Visual Context.*Video Frames") {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $failed = $true
}

# Check 3: Video Frames placeholder
Write-Host "[3] Video Frames Placeholder..." -NoNewline
if ($content -match "Video Frames \(Standby\)") {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $failed = $true
}

# Check 4: Frame placeholders (3 boxes)
Write-Host "[4] Frame Placeholder Boxes..." -NoNewline
$frameMatches = [regex]::Matches($content, "Frame \d+<br>not captured")
if ($frameMatches.Count -ge 3) {
    Write-Host " PASS ($($frameMatches.Count) found)" -ForegroundColor Green
} else {
    Write-Host " FAIL (only $($frameMatches.Count) found)" -ForegroundColor Red
    $failed = $true
}

# Check 5: Standby badge
Write-Host "[5] Standby Badge..." -NoNewline
if ($content -match "vision-status-badge standby") {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $failed = $true
}

# Check 6: Explainer text
Write-Host "[6] Explainer Text..." -NoNewline
if ($content -match "Activates automatically during detected risk") {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $failed = $true
}

# Check 7: Capture policy
Write-Host "[7] Capture Policy..." -NoNewline
if ($content -match "Capture policy.*video frames.*No continuous recording") {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $failed = $true
}

# Check 8: Vision/Video Status placeholder
Write-Host "[8] Vision/Video Status Placeholder..." -NoNewline
if ($content -match "Vision/Video Status.*Standby") {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $failed = $true
}

# Check 9: Progress indicators
Write-Host "[9] Progress Indicators..." -NoNewline
if ($content -match "progressTrigger" -and $content -match "progressCapture" -and $content -match "progressAnalyze" -and $content -match "progressPublish") {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $failed = $true
}

# Check 10: VisionContextController class
Write-Host "[10] VisionContextController Class..." -NoNewline
if ($content -match "class VisionContextController") {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $failed = $true
}

# Check 11: activateOnEmergency method
Write-Host "[11] activateOnEmergency Method..." -NoNewline
if ($content -match "activateOnEmergency\(keyword, transcript\)") {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $failed = $true
}

# Check 12: CSS styles
Write-Host "[12] Vision CSS Styles..." -NoNewline
if ($content -match "\.vision-context-panel" -and $content -match "\.vision-status-badge" -and $content -match "\.vision-frames-placeholder") {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $failed = $true
}

# Check 13: Evidence indicator
Write-Host "[13] Evidence Packet Indicator..." -NoNewline
if ($content -match "Added to Evidence Packet") {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $failed = $true
}

# Check 14: Why this helps text
Write-Host "[14] 'Why This Helps' Text..." -NoNewline
if ($content -match "Why this helps.*Visual context helps responders") {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $failed = $true
}

# Check 15: Build stamp
Write-Host "[15] Build Stamp..." -NoNewline
if ($content -match "GEMINI3-VISION-VIDEO-FIX-20260127") {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $failed = $true
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

if ($failed) {
    Write-Host "VERIFICATION FAILED" -ForegroundColor Red
    Write-Host "Some checks did not pass. Review the file." -ForegroundColor Red
    exit 1
} else {
    Write-Host "VERIFICATION PASSED" -ForegroundColor Green
    Write-Host "All checks passed. File is ready for deployment." -ForegroundColor Green
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# File size check
$fileSize = (Get-Item $UI_FILE).Length
$fileSizeKB = [math]::Round($fileSize / 1KB, 2)
Write-Host "File Size: $fileSizeKB KB" -ForegroundColor White
Write-Host ""

# Count lines
$lineCount = (Get-Content $UI_FILE).Count
Write-Host "Total Lines: $lineCount" -ForegroundColor White
Write-Host ""

Write-Host "Ready to deploy with:" -ForegroundColor Cyan
Write-Host "  .\deploy-vision-video-fix.ps1" -ForegroundColor White
Write-Host ""
