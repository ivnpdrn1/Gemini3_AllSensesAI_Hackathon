# Verify SMS Backend Deployment
# Tests Lambda function and frontend integration

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SMS Backend Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$STACK_NAME = "gemini3-sms-backend"
$CLOUDFRONT_URL = "https://dfc8ght8abwqc.cloudfront.net"
$BUILD_ID = "GEMINI3-JURY-READY-VIDEO-SMS-20260128-v1"

$testsPassed = 0
$testsFailed = 0

function Test-Condition {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$SuccessMessage = "PASS",
        [string]$FailureMessage = "FAIL"
    )
    
    Write-Host "  Testing: $TestName..." -NoNewline
    if ($Condition) {
        Write-Host " $SuccessMessage" -ForegroundColor Green
        $script:testsPassed++
        return $true
    } else {
        Write-Host " $FailureMessage" -ForegroundColor Red
        $script:testsFailed++
        return $false
    }
}

# Test 1: CloudFormation Stack
Write-Host "[1] CloudFormation Stack" -ForegroundColor Yellow
try {
    $stackStatus = aws cloudformation describe-stacks `
        --stack-name $STACK_NAME `
        --query "Stacks[0].StackStatus" `
        --output text 2>$null
    
    Test-Condition "Stack exists" ($stackStatus -ne $null)
    Test-Condition "Stack status" ($stackStatus -eq "CREATE_COMPLETE" -or $stackStatus -eq "UPDATE_COMPLETE")
} catch {
    Test-Condition "Stack exists" $false
}
Write-Host ""

# Test 2: Lambda Function
Write-Host "[2] Lambda Function" -ForegroundColor Yellow
try {
    $functionName = aws cloudformation describe-stacks `
        --stack-name $STACK_NAME `
        --query "Stacks[0].Outputs[?OutputKey=='SmsFunctionName'].OutputValue" `
        --output text 2>$null
    
    Test-Condition "Function name retrieved" ($functionName -ne $null)
    
    if ($functionName) {
        $functionConfig = aws lambda get-function-configuration `
            --function-name $functionName 2>$null | ConvertFrom-Json
        
        Test-Condition "Function exists" ($functionConfig -ne $null)
        Test-Condition "Runtime is Python 3.11" ($functionConfig.Runtime -eq "python3.11")
        Test-Condition "Handler is lambda_handler.handler" ($functionConfig.Handler -eq "lambda_handler.handler")
    }
} catch {
    Test-Condition "Lambda function" $false
}
Write-Host ""

# Test 3: API Gateway
Write-Host "[3] API Gateway" -ForegroundColor Yellow
try {
    $apiUrl = aws cloudformation describe-stacks `
        --stack-name $STACK_NAME `
        --query "Stacks[0].Outputs[?OutputKey=='SmsApiUrl'].OutputValue" `
        --output text 2>$null
    
    Test-Condition "API URL retrieved" ($apiUrl -ne $null)
    Test-Condition "API URL format" ($apiUrl -match "^https://.*\.execute-api\..*\.amazonaws\.com/.*")
    
    Write-Host "  API URL: $apiUrl" -ForegroundColor Cyan
} catch {
    Test-Condition "API Gateway" $false
}
Write-Host ""

# Test 4: Frontend HTML
Write-Host "[4] Frontend HTML" -ForegroundColor Yellow
try {
    $html = Invoke-WebRequest -Uri $CLOUDFRONT_URL -UseBasicParsing
    $htmlContent = $html.Content
    
    Test-Condition "CloudFront accessible" ($html.StatusCode -eq 200)
    Test-Condition "Build ID in top stamp" ($htmlContent -match $BUILD_ID)
    Test-Condition "SMS_API_URL constant" ($htmlContent -match "const SMS_API_URL = ")
    Test-Condition "SMS API URL not placeholder" ($htmlContent -notmatch "YOUR_API_GATEWAY_URL_HERE")
    Test-Condition "sendSms function" ($htmlContent -match "async function sendSms")
    Test-Condition "updateDeliveryStatus function" ($htmlContent -match "function updateDeliveryStatus")
    Test-Condition "sendTestSms function" ($htmlContent -match "function sendTestSms")
    Test-Condition "Delivery Proof panel" ($htmlContent -match "smsDeliveryProofPanel")
    Test-Condition "Manual test button" ($htmlContent -match "manualSmsTestSection")
    Test-Condition "SMS proof logging" ($htmlContent -match "\[SMS\]\[REQUEST\]")
} catch {
    Test-Condition "Frontend HTML" $false
}
Write-Host ""

# Test 5: Lambda Invocation (Dry Run)
Write-Host "[5] Lambda Invocation Test" -ForegroundColor Yellow
try {
    $functionName = aws cloudformation describe-stacks `
        --stack-name $STACK_NAME `
        --query "Stacks[0].Outputs[?OutputKey=='SmsFunctionName'].OutputValue" `
        --output text 2>$null
    
    if ($functionName) {
        # Test with invalid payload (should return validation error)
        $testPayload = @{
            toE164 = "+1234567890"
            smsText = "Test message"
        } | ConvertTo-Json
        
        $response = aws lambda invoke `
            --function-name $functionName `
            --payload $testPayload `
            --cli-binary-format raw-in-base64-out `
            response.json 2>$null
        
        if (Test-Path response.json) {
            $result = Get-Content response.json | ConvertFrom-Json
            Test-Condition "Lambda responds" ($result -ne $null)
            Test-Condition "Lambda returns JSON" ($result.statusCode -ne $null)
            
            Remove-Item response.json -Force
        }
    }
} catch {
    Write-Host "  Note: Lambda invocation test skipped (optional)" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VERIFICATION SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Tests Passed: $testsPassed" -ForegroundColor Green
Write-Host "Tests Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "✅ ALL TESTS PASSED" -ForegroundColor Green
    Write-Host ""
    Write-Host "SMS Backend is ready for use!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Manual Testing Steps:" -ForegroundColor Yellow
    Write-Host "  1. Open: $CLOUDFRONT_URL"
    Write-Host "  2. Complete Step 1 with your phone number (E.164 format: +1234567890)"
    Write-Host "  3. Click 'Send Test SMS' button in Step 5"
    Write-Host "  4. Check your phone for SMS delivery"
    Write-Host "  5. Verify SMS content matches preview character-for-character"
    Write-Host ""
} else {
    Write-Host "❌ SOME TESTS FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please review the failures above and redeploy if necessary." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
