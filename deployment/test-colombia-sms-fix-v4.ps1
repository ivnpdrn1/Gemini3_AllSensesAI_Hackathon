#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test Colombia SMS Fix V4 Deployment
    
.DESCRIPTION
    Verifies all acceptance criteria for GEMINI3-COLOMBIA-SMS-FIX-20260129-v3
    
.NOTES
    Tests:
    1. CloudFront shows Build ID v3 (not v1)
    2. Lambda returns proper API contract
    3. SMS delivery to Colombia number
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Configuration
$CLOUDFRONT_URL = "https://dfc8ght8abwqc.cloudfront.net"
$LAMBDA_URL = "https://q4ouvfydgod6o734zbfipyi45q0lyuhx.lambda-url.us-east-1.on.aws/"
$COLOMBIA_PHONE = "+573222063010"
$BUILD_ID = "GEMINI3-COLOMBIA-SMS-FIX-20260129-v3"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Colombia SMS Fix V4 - Acceptance Tests" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$passCount = 0
$failCount = 0

# ============================================================
# TEST 1: CloudFront Build ID
# ============================================================
Write-Host "[TEST 1] CloudFront Build ID Verification" -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri $CLOUDFRONT_URL -UseBasicParsing
    $html = $response.Content
    
    if ($html -match $BUILD_ID) {
        Write-Host "  ✅ PASS: Build ID v3 found in HTML" -ForegroundColor Green
        $passCount++
    } else {
        Write-Host "  ❌ FAIL: Build ID v3 NOT found in HTML" -ForegroundColor Red
        Write-Host "  Expected: $BUILD_ID" -ForegroundColor Yellow
        
        # Check for v1
        if ($html -match "GEMINI3-COLOMBIA-SMS-FIX-20260129-v1") {
            Write-Host "  Found: v1 (OLD BUILD - cache issue)" -ForegroundColor Red
        }
        $failCount++
    }
} catch {
    Write-Host "  ❌ FAIL: Could not fetch CloudFront URL" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Gray
    $failCount++
}

Write-Host ""

# ============================================================
# TEST 2: Lambda API Contract - Success Case
# ============================================================
Write-Host "[TEST 2] Lambda API Contract - Success Case" -ForegroundColor Yellow

$testPayload = @{
    to = $COLOMBIA_PHONE
    message = "TEST: AllSenses AI Guardian - Colombia SMS Fix V4 verification. This is a test message. Please ignore."
    buildId = $BUILD_ID
    meta = @{
        victimName = "Test User"
        risk = "TEST"
        lat = 4.6097
        lng = -74.0817
    }
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri $LAMBDA_URL -Method POST -Body $testPayload -ContentType "application/json" -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    
    Write-Host "  HTTP Status: $($response.StatusCode)" -ForegroundColor Gray
    Write-Host "  Response: $($response.Content)" -ForegroundColor Gray
    
    # Check HTTP 200
    if ($response.StatusCode -eq 200) {
        Write-Host "  ✅ HTTP 200 returned" -ForegroundColor Green
    } else {
        Write-Host "  ❌ HTTP status not 200: $($response.StatusCode)" -ForegroundColor Red
        $failCount++
    }
    
    # Check ok: true
    if ($data.ok -eq $true) {
        Write-Host "  ✅ data.ok === true" -ForegroundColor Green
    } else {
        Write-Host "  ❌ data.ok !== true (got: $($data.ok))" -ForegroundColor Red
        $failCount++
    }
    
    # Check messageId exists
    if ($data.messageId) {
        Write-Host "  ✅ messageId exists: $($data.messageId)" -ForegroundColor Green
        $passCount++
    } else {
        Write-Host "  ❌ messageId missing" -ForegroundColor Red
        $failCount++
    }
    
    # Check requestId exists
    if ($data.requestId) {
        Write-Host "  ✅ requestId exists: $($data.requestId)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ requestId missing" -ForegroundColor Red
        $failCount++
    }
    
    # Check provider
    if ($data.provider -eq "sns") {
        Write-Host "  ✅ provider === 'sns'" -ForegroundColor Green
    } else {
        Write-Host "  ❌ provider !== 'sns' (got: $($data.provider))" -ForegroundColor Red
        $failCount++
    }
    
} catch {
    Write-Host "  ❌ FAIL: Lambda request failed" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Gray
    $failCount++
}

Write-Host ""

# ============================================================
# TEST 3: Lambda API Contract - Failure Case (Invalid Phone)
# ============================================================
Write-Host "[TEST 3] Lambda API Contract - Failure Case" -ForegroundColor Yellow

$invalidPayload = @{
    to = "invalid-phone"
    message = "Test"
    buildId = $BUILD_ID
    meta = @{}
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri $LAMBDA_URL -Method POST -Body $invalidPayload -ContentType "application/json" -UseBasicParsing -SkipHttpErrorCheck
    $data = $response.Content | ConvertFrom-Json
    
    Write-Host "  HTTP Status: $($response.StatusCode)" -ForegroundColor Gray
    Write-Host "  Response: $($response.Content)" -ForegroundColor Gray
    
    # Check HTTP non-200
    if ($response.StatusCode -ne 200) {
        Write-Host "  ✅ HTTP non-200 returned ($($response.StatusCode))" -ForegroundColor Green
    } else {
        Write-Host "  ❌ HTTP 200 returned for invalid phone (should be 400)" -ForegroundColor Red
        $failCount++
    }
    
    # Check ok: false
    if ($data.ok -eq $false) {
        Write-Host "  ✅ data.ok === false" -ForegroundColor Green
    } else {
        Write-Host "  ❌ data.ok !== false (got: $($data.ok))" -ForegroundColor Red
        $failCount++
    }
    
    # Check errorCode exists
    if ($data.errorCode) {
        Write-Host "  ✅ errorCode exists: $($data.errorCode)" -ForegroundColor Green
        $passCount++
    } else {
        Write-Host "  ❌ errorCode missing" -ForegroundColor Red
        $failCount++
    }
    
    # Check errorMessage exists
    if ($data.errorMessage) {
        Write-Host "  ✅ errorMessage exists" -ForegroundColor Green
    } else {
        Write-Host "  ❌ errorMessage missing" -ForegroundColor Red
        $failCount++
    }
    
} catch {
    Write-Host "  ❌ FAIL: Lambda request failed unexpectedly" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Gray
    $failCount++
}

Write-Host ""

# ============================================================
# TEST 4: CloudFront Invalidation Status
# ============================================================
Write-Host "[TEST 4] CloudFront Invalidation Status" -ForegroundColor Yellow

try {
    $invalidation = aws cloudfront get-invalidation --distribution-id E2NIUI2KOXAO0Q --id IDY68UPLFD0V7IFXCQHMVB0KS7 | ConvertFrom-Json
    $status = $invalidation.Invalidation.Status
    
    Write-Host "  Status: $status" -ForegroundColor Gray
    
    if ($status -eq "Completed") {
        Write-Host "  ✅ PASS: Invalidation completed" -ForegroundColor Green
        $passCount++
    } else {
        Write-Host "  ⏳ IN PROGRESS: Invalidation still running" -ForegroundColor Yellow
        Write-Host "  Wait 1-3 minutes and test again" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️  Could not check invalidation status" -ForegroundColor Yellow
    Write-Host "  Error: $_" -ForegroundColor Gray
}

Write-Host ""

# ============================================================
# SUMMARY
# ============================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red
Write-Host ""

if ($failCount -eq 0) {
    Write-Host "✅ ALL TESTS PASSED" -ForegroundColor Green
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor White
    Write-Host "1. Open CloudFront URL in incognito window: $CLOUDFRONT_URL" -ForegroundColor White
    Write-Host "2. Complete Steps 1-4 in the UI" -ForegroundColor White
    Write-Host "3. Send test SMS to Colombia number" -ForegroundColor White
    Write-Host "4. Verify SMS arrives on phone" -ForegroundColor White
    Write-Host "5. Check Delivery Proof panel shows SENT + MessageId" -ForegroundColor White
} else {
    Write-Host "❌ SOME TESTS FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "TROUBLESHOOTING:" -ForegroundColor Yellow
    Write-Host "- If Build ID test failed: Wait for CloudFront invalidation to complete" -ForegroundColor White
    Write-Host "- If Lambda tests failed: Check CloudWatch logs for errors" -ForegroundColor White
    Write-Host "- Clear browser cache and try incognito window" -ForegroundColor White
}

Write-Host ""
