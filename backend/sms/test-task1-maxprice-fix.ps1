# Colombia SMS Task 1 Test Script
# Tests Lambda function with MaxPrice, SMSType, and SenderID attributes

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Colombia SMS Task 1 - Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get Lambda Function URL
Write-Host "[1/4] Getting Lambda Function URL..." -ForegroundColor Yellow
try {
    $urlConfig = aws lambda get-function-url-config `
        --function-name allsenses-sms-production `
        --output json 2>&1 | ConvertFrom-Json
    
    $functionUrl = $urlConfig.FunctionUrl
    Write-Host "✓ Function URL: $functionUrl" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "ERROR: Could not retrieve Function URL" -ForegroundColor Red
    Write-Host "Please ensure the Lambda function exists and has a Function URL configured" -ForegroundColor Yellow
    exit 1
}

# Test 1: USA Number (Baseline)
Write-Host "[2/4] Test 1: USA Number (Baseline)" -ForegroundColor Yellow
$usaPayload = @{
    to = "+12025551234"
    message = "TEST: AllSenses emergency alert - USA baseline test"
    buildId = "task1-test-usa"
    meta = @{
        victimName = "Test User USA"
        risk = "HIGH"
        lat = 38.9072
        lng = -77.0369
    }
} | ConvertTo-Json

try {
    $usaResponse = Invoke-RestMethod -Uri $functionUrl -Method Post -Body $usaPayload -ContentType "application/json"
    
    if ($usaResponse.ok -eq $true) {
        Write-Host "✓ USA SMS sent successfully" -ForegroundColor Green
        Write-Host "  MessageId: $($usaResponse.messageId)" -ForegroundColor Gray
        Write-Host "  To (masked): $($usaResponse.toMasked)" -ForegroundColor Gray
        Write-Host "  Provider: $($usaResponse.provider)" -ForegroundColor Gray
    } else {
        Write-Host "✗ USA SMS failed" -ForegroundColor Red
        Write-Host "  Error: $($usaResponse.errorMessage)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ USA SMS request failed" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 2: Colombia Number (Primary Test)
Write-Host "[3/4] Test 2: Colombia Number (Primary Test)" -ForegroundColor Yellow
$colombiaPayload = @{
    to = "+573001234567"
    message = "TEST: AllSenses emergency alert - Colombia MaxPrice test"
    buildId = "task1-test-colombia"
    meta = @{
        victimName = "Test User Colombia"
        risk = "CRITICAL"
        lat = 4.6097
        lng = -74.0817
    }
} | ConvertTo-Json

try {
    $colombiaResponse = Invoke-RestMethod -Uri $functionUrl -Method Post -Body $colombiaPayload -ContentType "application/json"
    
    if ($colombiaResponse.ok -eq $true) {
        Write-Host "✓ Colombia SMS sent successfully" -ForegroundColor Green
        Write-Host "  MessageId: $($colombiaResponse.messageId)" -ForegroundColor Gray
        Write-Host "  To (masked): $($colombiaResponse.toMasked)" -ForegroundColor Gray
        Write-Host "  Provider: $($colombiaResponse.provider)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  ⚠ IMPORTANT: Check your Colombia phone for SMS delivery" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Colombia SMS failed" -ForegroundColor Red
        Write-Host "  Error Code: $($colombiaResponse.errorCode)" -ForegroundColor Red
        Write-Host "  Error Message: $($colombiaResponse.errorMessage)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Colombia SMS request failed" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 3: Invalid Phone Number (Validation Test)
Write-Host "[4/4] Test 3: Invalid Phone Number (Validation Test)" -ForegroundColor Yellow
$invalidPayload = @{
    to = "3001234567"  # Missing + prefix
    message = "TEST: This should fail validation"
    buildId = "task1-test-invalid"
} | ConvertTo-Json

try {
    $invalidResponse = Invoke-RestMethod -Uri $functionUrl -Method Post -Body $invalidPayload -ContentType "application/json" -ErrorAction Stop
    
    if ($invalidResponse.ok -eq $false -and $invalidResponse.errorCode -eq "INVALID_PHONE_FORMAT") {
        Write-Host "✓ Invalid phone number correctly rejected" -ForegroundColor Green
        Write-Host "  Error Code: $($invalidResponse.errorCode)" -ForegroundColor Gray
    } else {
        Write-Host "✗ Invalid phone number should have been rejected" -ForegroundColor Red
    }
} catch {
    # Expected to fail with 400 status
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "✓ Invalid phone number correctly rejected (HTTP 400)" -ForegroundColor Green
    } else {
        Write-Host "✗ Unexpected error" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Suite Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "- USA SMS: Baseline test for comparison" -ForegroundColor White
Write-Host "- Colombia SMS: Primary test with MaxPrice=$0.50" -ForegroundColor White
Write-Host "- Invalid Phone: Validation test" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Check CloudWatch Logs for SNS publish details" -ForegroundColor White
Write-Host "2. Verify SMS arrives on Colombia phone within 30 seconds" -ForegroundColor White
Write-Host "3. Compare delivery success between USA and Colombia" -ForegroundColor White
Write-Host ""
Write-Host "CloudWatch Logs Command:" -ForegroundColor Yellow
Write-Host "aws logs tail /aws/lambda/allsenses-sms-production --follow" -ForegroundColor Gray
Write-Host ""
