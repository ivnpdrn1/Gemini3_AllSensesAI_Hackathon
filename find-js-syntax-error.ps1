# Find JavaScript Syntax Errors in Deployed Version
# Downloads and checks for syntax errors that prevent script loading

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "JavaScript Syntax Error Detection" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$CLOUDFRONT_URL = "https://dfc8ght8abwqc.cloudfront.net"

Write-Host "[1/2] Fetching deployed version..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri $CLOUDFRONT_URL -UseBasicParsing -Headers @{
        "Cache-Control" = "no-cache"
        "Pragma" = "no-cache"
    }
    
    $content = $response.Content
    Write-Host "   Fetched successfully" -ForegroundColor Green
} catch {
    Write-Host "   Failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/2] Analyzing JavaScript..." -ForegroundColor Cyan

# Extract script content
if ($content -match '(?s)<script>(.*?)</script>') {
    $scriptContent = $matches[1]
    Write-Host "   Extracted JavaScript ($($scriptContent.Length) bytes)" -ForegroundColor Green
    
    # Save to temp file for analysis
    $tempFile = "temp-deployed-script.js"
    $scriptContent | Out-File -FilePath $tempFile -Encoding UTF8
    Write-Host "   Saved to: $tempFile" -ForegroundColor Gray
} else {
    Write-Host "   ERROR: Could not extract <script> tag" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Common Syntax Errors to Check:" -ForegroundColor Yellow
Write-Host ""

# Check for common issues
$issues = @()

# Check for unclosed strings
$unclosedStrings = ([regex]::Matches($scriptContent, '(?<!\\)"[^"]*$')).Count
if ($unclosedStrings -gt 0) {
    $issues += "Unclosed string literals detected"
}

# Check for unclosed comments
if ($scriptContent -match '/\*(?!.*\*/)') {
    $issues += "Unclosed /* comment block detected"
}

# Check for emoji characters (UTF-8 issues)
# Simplified check - look for common emoji patterns
if ($scriptContent -match '[\u2600-\u27BF]|[\uD800-\uDBFF][\uDC00-\uDFFF]') {
    $issues += "Emoji characters detected (UTF-8 encoding issue)"
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

if ($issues.Count -eq 0) {
    Write-Host "   No obvious syntax errors detected" -ForegroundColor Green
    Write-Host ""
    Write-Host "   The issue may be:" -ForegroundColor Yellow
    Write-Host "   - Browser cache (try Ctrl+Shift+R)" -ForegroundColor White
    Write-Host "   - CloudFront cache (wait 60 seconds)" -ForegroundColor White
    Write-Host "   - Runtime error (check browser console)" -ForegroundColor White
} else {
    Write-Host "   SYNTAX ERRORS DETECTED:" -ForegroundColor Red
    Write-Host ""
    foreach ($issue in $issues) {
        Write-Host "   - $issue" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "   These errors prevent the script from loading!" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Check browser console for specific error message" -ForegroundColor White
Write-Host "   2. Look for line number in error message" -ForegroundColor White
Write-Host "   3. Review temp-deployed-script.js around that line" -ForegroundColor White
Write-Host ""
