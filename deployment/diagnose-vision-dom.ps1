# Diagnose Vision Panel DOM Rendering
# This script checks if the Vision panel exists in the deployed CloudFront file

Write-Host "=== Vision Panel DOM Diagnostic ===" -ForegroundColor Cyan
Write-Host ""

# Check if Vision panel HTML exists in deployed file
Write-Host "1. Checking Vision panel HTML in deployed file..." -ForegroundColor Yellow
$visionPanelExists = Select-String -Path "Gemini3_AllSensesAI/deployment/ui/index.html" -Pattern "visionContextPanel" -Quiet
if ($visionPanelExists) {
    Write-Host "   ✅ Vision panel HTML found in file" -ForegroundColor Green
} else {
    Write-Host "   ❌ Vision panel HTML NOT found in file" -ForegroundColor Red
}

# Check Step 4 structure
Write-Host ""
Write-Host "2. Checking Step 4 structure..." -ForegroundColor Yellow
$step4Active = Select-String -Path "Gemini3_AllSensesAI/deployment/ui/index.html" -Pattern 'id="step4".*class="step active"' -Quiet
if ($step4Active) {
    Write-Host "   ✅ Step 4 has 'active' class" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Step 4 may not have 'active' class" -ForegroundColor Yellow
}

# Check Vision panel placement
Write-Host ""
Write-Host "3. Extracting Vision panel location..." -ForegroundColor Yellow
$lines = Get-Content "Gemini3_AllSensesAI/deployment/ui/index.html"
$visionLineNumber = 0
$step4ContentLineNumber = 0

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'id="visionContextPanel"') {
        $visionLineNumber = $i + 1
    }
    if ($lines[$i] -match 'id="step4".*class="step active"') {
        $step4ContentLineNumber = $i + 1
    }
}

Write-Host "   Vision panel at line: $visionLineNumber" -ForegroundColor Cyan
Write-Host "   Step 4 starts at line: $step4ContentLineNumber" -ForegroundColor Cyan

if ($visionLineNumber -gt $step4ContentLineNumber -and $visionLineNumber -lt ($step4ContentLineNumber + 200)) {
    Write-Host "   ✅ Vision panel is INSIDE Step 4 content" -ForegroundColor Green
} else {
    Write-Host "   ❌ Vision panel may be OUTSIDE Step 4 content" -ForegroundColor Red
}

# Check for display:none or hidden attributes
Write-Host ""
Write-Host "4. Checking for hidden attributes..." -ForegroundColor Yellow
$hiddenVision = Select-String -Path "Gemini3_AllSensesAI/deployment/ui/index.html" -Pattern 'id="visionContextPanel".*display:\s*none' -Quiet
if ($hiddenVision) {
    Write-Host "   ❌ Vision panel has display:none inline style" -ForegroundColor Red
} else {
    Write-Host "   ✅ No display:none found on Vision panel" -ForegroundColor Green
}

# Extract Vision panel HTML snippet
Write-Host ""
Write-Host "5. Vision panel HTML snippet:" -ForegroundColor Yellow
$visionSnippet = Select-String -Path "Gemini3_AllSensesAI/deployment/ui/index.html" -Pattern "visionContextPanel" -Context 2,2
Write-Host $visionSnippet -ForegroundColor Gray

Write-Host ""
Write-Host "=== Diagnostic Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. If Vision panel HTML exists but isn't visible, check browser DevTools:" -ForegroundColor White
Write-Host "   - Open CloudFront URL" -ForegroundColor White
Write-Host "   - Press F12 to open DevTools" -ForegroundColor White
Write-Host "   - Search for 'visionContextPanel' in Elements tab" -ForegroundColor White
Write-Host "   - Check if element exists and has display:block" -ForegroundColor White
Write-Host ""
Write-Host "2. If element doesn't exist in browser, file may not be deployed:" -ForegroundColor White
Write-Host "   - Run: aws s3 cp Gemini3_AllSensesAI/deployment/ui/index.html s3://YOUR-BUCKET/index.html" -ForegroundColor White
Write-Host "   - Run: aws cloudfront create-invalidation --distribution-id YOUR-DIST-ID --paths '/*'" -ForegroundColor White
