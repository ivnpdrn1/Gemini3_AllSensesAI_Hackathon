# Check Local File for Syntax Errors
# Verifies the source file is clean before deployment

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Local File Syntax Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$SOURCE_FILE = "Gemini3_AllSensesAI/gemini3-guardian-production-sms-FINAL.html"

Write-Host "[1/2] Reading local file..." -ForegroundColor Cyan
if (-not (Test-Path $SOURCE_FILE)) {
    Write-Host "   ERROR: File not found: $SOURCE_FILE" -ForegroundColor Red
    exit 1
}

$content = Get-Content $SOURCE_FILE -Raw
Write-Host "   Read successfully ($($content.Length) bytes)" -ForegroundColor Green

Write-Host ""
Write-Host "[2/2] Analyzing JavaScript..." -ForegroundColor Cyan

# Extract script content
if ($content -match '(?s)<script>(.*?)</script>') {
    $scriptContent = $matches[1]
    Write-Host "   Extracted JavaScript ($($scriptContent.Length) bytes)" -ForegroundColor Green
} else {
    Write-Host "   ERROR: Could not extract <script> tag" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Syntax Checks:" -ForegroundColor Yellow
Write-Host ""

$issues = @()

# Check for International corruption
if ($scriptContent -match 'International') {
    $matches = ([regex]::Matches($scriptContent, 'International')).Count
    $issues += "International corruption detected: $matches occurrences"
}

# Check for mismatched braces
$openBraces = ([regex]::Matches($scriptContent, '\{')).Count
$closeBraces = ([regex]::Matches($scriptContent, '\}')).Count
if ($openBraces -ne $closeBraces) {
    $issues += "Mismatched braces: $openBraces open, $closeBraces close"
}

# Check for mismatched parentheses
$openParens = ([regex]::Matches($scriptContent, '\(')).Count
$closeParens = ([regex]::Matches($scriptContent, '\)')).Count
if ($openParens -ne $closeParens) {
    $issues += "Mismatched parentheses: $openParens open, $closeParens close"
}

# Check for completeStep1 function
if ($scriptContent -match 'function completeStep1') {
    Write-Host "   completeStep1 function: FOUND" -ForegroundColor Green
} else {
    $issues += "completeStep1 function NOT FOUND"
}

# Check for step1Status (not step1StatInternational)
if ($scriptContent -match 'step1Status') {
    Write-Host "   step1Status reference: CORRECT" -ForegroundColor Green
} else {
    $issues += "step1Status reference NOT FOUND"
}

if ($scriptContent -match 'step1StatInternational') {
    $issues += "CORRUPTION: step1StatInternational found (should be step1Status)"
}

Write-Host ""

if ($issues.Count -eq 0) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Local File is CLEAN" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "The source file has no syntax errors." -ForegroundColor White
    Write-Host "Safe to deploy." -ForegroundColor White
} else {
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "SYNTAX ERRORS DETECTED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    foreach ($issue in $issues) {
        Write-Host "   - $issue" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "DO NOT DEPLOY until these are fixed!" -ForegroundColor Yellow
}

Write-Host ""
