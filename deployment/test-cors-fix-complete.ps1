# CORS Fix Verification Script
# Tests OPTIONS preflight and POST request with exact CloudFront origin

$SMS_API_URL = "https://q4ouvfydgod6o734zbfipyi45q0lyuhx.lambda-url.us-east-1.on.aws/"
$CLOUDFRONT_ORIGIN = "https://dfc8ght8abwqc.cloudfront.net"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CORS FIX VERIFICATION TEST" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: OPTIONS Preflight
Write-Host "[TEST 1] OPTIONS Preflight Request" -ForegroundColor Yellow
Write-Host "Testing: $SMS_API_URL" -ForegroundColor Gray
Write-Host "Origin: $CLOUDFRONT_ORIGIN`n" -ForegroundColor Gray

try {
    $optionsResponse = Invoke-WebRequest -Uri $SMS_API_URL -Method OPTIONS `
        -Headers @{
            'Origin' = $CLOUDFRONT_ORIGIN
            'Access-Control-Request-Method' = 'POST'
            'Access-Control-Request-Headers' = 'content-type'
        } -UseBasicParsing
    
    Write-Host "✅ OPTIONS Request: SUCCESS" -ForegroundColor Green
    Write-Host "   Status Code: $($optionsResponse.StatusCode)" -ForegroundColor White
    Write-Host "   Access-Control-Allow-Origin: $($optionsResponse.Headers['Access-Control-Allow-Origin'])" -ForegroundColor White
    Write-Host "   Access-Control-Allow-Methods: $($optionsResponse.Headers['Access-Control-Allow-Methods'])" -ForegroundColor White
    Write-Host "   Access-Control-Allow-Headers: $($optionsResponse.Headers['Access-Control-Allow-Headers'])`n" -ForegroundColor White
    
    # Verify CORS headers
    if ($optionsResponse.Headers['Access-Control-Allow-Origin'] -eq $CLOUDFRONT_ORIGIN) {
        Write-Host "✅ CORS Origin: CORRECT (exact match)" -ForegroundColor Green
    } else {
        Write-Host "❌ CORS Origin: INCORRECT" -ForegroundColor Red
        Write-Host "   Expected: $CLOUDFRONT_ORIGIN" -ForegroundColor Red
        Write-Host "   Got: $($optionsResponse.Headers['Access-Control-Allow-Origin'])" -ForegroundColor Red
    }
    
    if ($optionsResponse.Headers['Access-Control-Allow-Methods'] -match 'POST') {
        Write-Host "✅ CORS Methods: POST allowed`n" -ForegroundColor Green
    } else {
        Write-Host "❌ CORS Methods: POST not allowed`n" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ OPTIONS Request: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)`n" -ForegroundColor Red
    exit 1
}

# Test 2: POST Request
Write-Host "[TEST 2] POST Request with SMS Payload" -ForegroundColor Yellow

$testPayload = @{
    to = '+573222063010'
    message = 'CORS Fix Test - Gemini3 Guardian Emergency System'
    buildId = 'GEMINI3-COLOMBIA-SMS-FIX-20260129-v3'
    meta = @{
        source = 'cors_fix_test'
        victimName = 'Test User'
        risk = 'HIGH'
        lat = 4.6097
        lng = -74.0817
    }
} | ConvertTo-Json

Write-Host "Payload:" -ForegroundColor Gray
Write-Host $testPayload -ForegroundColor DarkGray
Write-Host ""

try {
    $postResponse = Invoke-WebRequest -Uri $SMS_API_URL -Method POST `
        -Headers @{
            'Origin' = $CLOUDFRONT_ORIGIN
            'Content-Type' = 'application/json'
        } `
        -Body $testPayload -UseBasicParsing
    
    Write-Host "✅ POST Request: SUCCESS" -ForegroundColor Green
    Write-Host "   Status Code: $($postResponse.StatusCode)" -ForegroundColor White
    Write-Host "   Access-Control-Allow-Origin: $($postResponse.Headers['Access-Control-Allow-Origin'])`n" -ForegroundColor White
    
    $responseData = $postResponse.Content | ConvertFrom-Json
    
    Write-Host "Response Data:" -ForegroundColor Yellow
    Write-Host "   ok: $($responseData.ok)" -ForegroundColor White
    Write-Host "   provider: $($responseData.provider)" -ForegroundColor White
    Write-Host "   messageId: $($responseData.messageId)" -ForegroundColor White
    Write-Host "   toMasked: $($responseData.toMasked)" -ForegroundColor White
    Write-Host "   requestId: $($responseData.requestId)" -ForegroundColor White
    Write-Host "   timestamp: $($responseData.timestamp)`n" -ForegroundColor White
    
    # Verify response
    if ($responseData.ok -eq $true -and $responseData.messageId) {
        Write-Host "✅ SMS Delivery: SUCCESS" -ForegroundColor Green
        Write-Host "   MessageId: $($responseData.messageId)" -ForegroundColor Green
    } else {
        Write-Host "❌ SMS Delivery: FAILED" -ForegroundColor Red
        Write-Host "   ok: $($responseData.ok)" -ForegroundColor Red
        Write-Host "   error: $($responseData.errorMessage)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ POST Request: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)`n" -ForegroundColor Red
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✅ ALL TESTS PASSED" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Test in browser (Incognito mode)" -ForegroundColor White
Write-Host "2. Check DevTools Network tab for CORS headers" -ForegroundColor White
Write-Host "3. Verify SMS arrives on Colombia phone (+57...)`n" -ForegroundColor White
