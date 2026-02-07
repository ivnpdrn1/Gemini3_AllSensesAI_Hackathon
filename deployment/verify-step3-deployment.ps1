# Verify Step 3 Keywords Configuration Deployment
# Checks what's currently deployed on CloudFront

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 3 Deployment Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$CLOUDFRONT_URL = "https://dfc8ght8abwqc.cloudfront.net"
$S3_BUCKET = "gemini3-guardian-prod-20260127120521"
$S3_KEY = "index.html"

Write-Host "[1/3] Fetching deployed HTML from CloudFront..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri $CLOUDFRONT_URL -UseBasicParsing -TimeoutSec 30
    $deployedHtml = $response.Content
    Write-Host "   Success: Fetched $($deployedHtml.Length) bytes" -ForegroundColor Green
} catch {
    Write-Host "   Error: Could not fetch from CloudFront: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

Write-Host "[2/3] Checking for Step 3 Keywords UI..." -ForegroundColor Cyan

# Check for keywords configuration UI
$hasKeywordsConfig = $deployedHtml -match "keywords-config"
$hasKeywordsClass = $deployedHtml -match "EmergencyKeywordsConfig"
$hasKeywordCounter = $deployedHtml -match "keywordCounter"
$hasKeywordsList = $deployedHtml -match "keywordsList"
$hasAddKeywordBtn = $deployedHtml -match "addKeywordBtn"

Write-Host ""
Write-Host "   Feature Detection:" -ForegroundColor Yellow
Write-Host "   - Keywords Config Panel: $(if ($hasKeywordsConfig) { '✅ FOUND' } else { '❌ NOT FOUND' })" -ForegroundColor $(if ($hasKeywordsConfig) { 'Green' } else { 'Red' })
Write-Host "   - EmergencyKeywordsConfig Class: $(if ($hasKeywordsClass) { '✅ FOUND' } else { '❌ NOT FOUND' })" -ForegroundColor $(if ($hasKeywordsClass) { 'Green' } else { 'Red' })
Write-Host "   - Keyword Counter: $(if ($hasKeywordCounter) { '✅ FOUND' } else { '❌ NOT FOUND' })" -ForegroundColor $(if ($hasKeywordCounter) { 'Green' } else { 'Red' })
Write-Host "   - Keywords List: $(if ($hasKeywordsList) { '✅ FOUND' } else { '❌ NOT FOUND' })" -ForegroundColor $(if ($hasKeywordsList) { 'Green' } else { 'Red' })
Write-Host "   - Add Keyword Button: $(if ($hasAddKeywordBtn) { '✅ FOUND' } else { '❌ NOT FOUND' })" -ForegroundColor $(if ($hasAddKeywordBtn) { 'Green' } else { 'Red' })

Write-Host ""

# Check for Step 1 and Step 2 features
Write-Host "[3/3] Checking for Step 1 & Step 2 features..." -ForegroundColor Cyan

$hasStep1 = $deployedHtml -match "victimName"
$hasStep2 = $deployedHtml -match "selectedLocationPanel"
$hasGoogleMaps = $deployedHtml -match "googleMapsLink"

Write-Host ""
Write-Host "   Core Features:" -ForegroundColor Yellow
Write-Host "   - Step 1 Configuration: $(if ($hasStep1) { '✅ FOUND' } else { '❌ NOT FOUND' })" -ForegroundColor $(if ($hasStep1) { 'Green' } else { 'Red' })
Write-Host "   - Step 2 Location Services: $(if ($hasStep2) { '✅ FOUND' } else { '❌ NOT FOUND' })" -ForegroundColor $(if ($hasStep2) { 'Green' } else { 'Red' })
Write-Host "   - Google Maps Integration: $(if ($hasGoogleMaps) { '✅ FOUND' } else { '❌ NOT FOUND' })" -ForegroundColor $(if ($hasGoogleMaps) { 'Green' } else { 'Red' })

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verification Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allStep3Features = $hasKeywordsConfig -and $hasKeywordsClass -and $hasKeywordCounter -and $hasKeywordsList -and $hasAddKeywordBtn
$allCoreFeatures = $hasStep1 -and $hasStep2 -and $hasGoogleMaps

if ($allStep3Features -and $allCoreFeatures) {
    Write-Host "Status: ✅ ALL FEATURES DEPLOYED" -ForegroundColor Green
    Write-Host ""
    Write-Host "Deployed Version:" -ForegroundColor Yellow
    Write-Host "   - Step 1: Configuration ✅" -ForegroundColor Green
    Write-Host "   - Step 2: Location Services with Google Maps ✅" -ForegroundColor Green
    Write-Host "   - Step 3: Emergency Keywords Configuration ✅" -ForegroundColor Green
    Write-Host ""
    Write-Host "CloudFront URL: $CLOUDFRONT_URL" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Ready for testing!" -ForegroundColor Green
} elseif ($allCoreFeatures -and -not $allStep3Features) {
    Write-Host "Status: ⚠️ STEP 3 NOT DEPLOYED" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Current Version:" -ForegroundColor Yellow
    Write-Host "   - Step 1: Configuration ✅" -ForegroundColor Green
    Write-Host "   - Step 2: Location Services with Google Maps ✅" -ForegroundColor Green
    Write-Host "   - Step 3: Emergency Keywords Configuration ❌" -ForegroundColor Red
    Write-Host ""
    Write-Host "Action Required:" -ForegroundColor Yellow
    Write-Host "   Run: .\Gemini3_AllSensesAI\deployment\deploy-step3-keywords-config.ps1" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "Status: ❌ INCOMPLETE DEPLOYMENT" -ForegroundColor Red
    Write-Host ""
    Write-Host "Missing Features:" -ForegroundColor Red
    if (-not $hasStep1) { Write-Host "   - Step 1 Configuration" -ForegroundColor Red }
    if (-not $hasStep2) { Write-Host "   - Step 2 Location Services" -ForegroundColor Red }
    if (-not $hasGoogleMaps) { Write-Host "   - Google Maps Integration" -ForegroundColor Red }
    if (-not $allStep3Features) { Write-Host "   - Step 3 Keywords Configuration" -ForegroundColor Red }
    Write-Host ""
    Write-Host "Action Required:" -ForegroundColor Yellow
    Write-Host "   Deploy the complete version with all features" -ForegroundColor White
    Write-Host ""
}

Write-Host "S3 Bucket: $S3_BUCKET" -ForegroundColor Gray
Write-Host "S3 Key: $S3_KEY" -ForegroundColor Gray
Write-Host ""

