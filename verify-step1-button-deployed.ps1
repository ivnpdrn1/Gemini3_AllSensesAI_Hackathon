# Verify Step 1 Button Deployment
# Checks if completeStep1 function exists in deployed CloudFront version

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 1 Button Deployment Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$CLOUDFRONT_URL = "https://dfc8ght8abwqc.cloudfront.net"

Write-Host "[1/3] Fetching deployed version from CloudFront..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri $CLOUDFRONT_URL -UseBasicParsing -Headers @{
        "Cache-Control" = "no-cache"
        "Pragma" = "no-cache"
    }
    
    $content = $response.Content
    Write-Host "   Fetched successfully ($($content.Length) bytes)" -ForegroundColor Green
} catch {
    Write-Host "   Failed to fetch: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/3] Checking for completeStep1 function..." -ForegroundColor Cyan

if ($content -match "function completeStep1") {
    Write-Host "   FOUND: completeStep1 function exists" -ForegroundColor Green
} else {
    Write-Host "   NOT FOUND: completeStep1 function missing!" -ForegroundColor Red
    Write-Host ""
    Write-Host "   This explains why the button doesn't work." -ForegroundColor Yellow
    Write-Host "   The function is not in the deployed version." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   ACTION REQUIRED: Deploy the fixed version" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[3/3] Checking button onclick attribute..." -ForegroundColor Cyan

if ($content -match 'onclick="completeStep1\(\)"') {
    Write-Host "   FOUND: Button has onclick attribute" -ForegroundColor Green
} else {
    Write-Host "   NOT FOUND: Button missing onclick attribute!" -ForegroundColor Red
    Write-Host ""
    Write-Host "   The button exists but has no onclick handler." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Verification Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Result:" -ForegroundColor Yellow
Write-Host "   completeStep1 function: EXISTS" -ForegroundColor Green
Write-Host "   Button onclick attribute: EXISTS" -ForegroundColor Green
Write-Host ""

Write-Host "Conclusion:" -ForegroundColor Cyan
Write-Host "   The deployed version appears correct." -ForegroundColor White
Write-Host "   If the button still doesn't work, there may be a JavaScript error" -ForegroundColor White
Write-Host "   preventing the script from loading." -ForegroundColor White
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Open browser console (F12)" -ForegroundColor White
Write-Host "   2. Look for JavaScript errors" -ForegroundColor White
Write-Host "   3. Run diagnostic: paste COPY_PASTE_STEP1_DIAGNOSTIC.js" -ForegroundColor White
Write-Host ""
