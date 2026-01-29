# Verify SMS Delivery to Colombia +57
# Tests end-to-end SMS delivery with real Colombia phone number

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Colombia SMS Delivery Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$COLOMBIA_PHONE = "+573222063010"
$LAMBDA_FUNCTION = "gemini3-sms-sender-prod"
$CLOUDFRONT_URL = "https://dfc8ght8abwqc.cloudfront.net"
$BUILD_ID = "GEMINI3-JURY-READY-VIDEO-SMS-20260128-v2"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Test Phone: $COLOMBIA_PHONE"
Write-Host "  Lambda: $LAMBDA_FUNCTION"
Write-Host "  CloudFront: $CLOUDFRONT_URL"
Write-Host "  Build ID: $BUILD_ID"
Write-Host ""

# Test 1: Lambda Direct Invocation
Write-Host "[1/4] Testing Lambda direct invocation..." -ForegroundColor Green

$testPayload = @{
    to = $COLOMBIA_PHONE
    message = "🚨 TEST: AllSensesAI Guardian SMS delivery test to Colombia. Build: $BUILD_ID. If you receive this, SMS is working!"
    buildId = $BUILD_ID
    meta = @{
        victimName = "Test User"
        risk = "TEST"
        lat = 4.7110
        lng = -74.0721
        timestampIso = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }
} | ConvertTo-Json -Compress

Write-Host "  Payload:" -ForegroundColor Yellow
Write-Host "    Phone: $COLOMBIA_PHONE"
Write-Host "    Message length: $($testPayload.Length) chars"
Write-Host ""

# Save payload to temp file
$payloadFile = "test-colombia-payload.json"
$testPayload | Out-File -FilePath $payloadFile -Encoding UTF8 -NoNewline

Write-Host "  Invoking Lambda..." -ForegroundColor Yellow
try {
    $response = aws lambda invoke `
        --function-name $LAMBDA_FUNCTION `
        --payload file://$payloadFile `
        --cli-binary-format raw-in-base64-out `
        response-colombia.json
    
    if ($LASTEXITCODE -ne 0) {
        throw "Lambda invocation failed"
    }
    
    $result = Get-Content response-colombia.json -Raw | ConvertFrom-Json
    
    if ($result.statusCode -eq 200) {
        $body = $result.body | ConvertFrom-Json
        if ($body.ok) {
            Write-Host "  ✅ Lambda invocation successful" -ForegroundColor Green
            Write-Host "    Message ID: $($body.messageId)" -ForegroundColor Green
            Write-Host "    Destination: $($body.toMasked)" -ForegroundColor Green
            Write-Host "    Timestamp: $($body.timestamp)" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Lambda returned error: $($body.errorMessage)" -ForegroundColor Red
            Write-Host "    Error code: $($body.errorCode)" -ForegroundColor Red
        }
    } else {
        Write-Host "  ❌ Lambda returned status code: $($result.statusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Lambda invocation failed: $_" -ForegroundColor Red
} finally {
    # Cleanup
    if (Test-Path $payloadFile) { Remove-Item $payloadFile }
    if (Test-Path response-colombia.json) { Remove-Item response-colombia.json }
}
Write-Host ""

# Test 2: Check Lambda Logs
Write-Host "[2/4] Checking Lambda logs..." -ForegroundColor Green
Write-Host "  Fetching last 20 log entries..." -ForegroundColor Yellow

try {
    $logOutput = aws logs tail /aws/lambda/$LAMBDA_FUNCTION --since 5m --format short 2>&1
    
    if ($logOutput -match "SMS published successfully") {
        Write-Host "  ✅ Found successful SMS publish in logs" -ForegroundColor Green
    } elseif ($logOutput -match "SMS-LAMBDA.*ERROR") {
        Write-Host "  ❌ Found errors in logs" -ForegroundColor Red
        Write-Host "    Check full logs with: aws logs tail /aws/lambda/$LAMBDA_FUNCTION --follow" -ForegroundColor Yellow
    } else {
        Write-Host "  ⚠️  No recent SMS activity in logs" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️  Could not fetch logs: $_" -ForegroundColor Yellow
}
Write-Host ""

# Test 3: Check SNS Delivery Logs
Write-Host "[3/4] Checking SNS delivery logs..." -ForegroundColor Green
Write-Host "  Note: Delivery logs may take 1-2 minutes to appear" -ForegroundColor Yellow

try {
    $accountId = aws sts get-caller-identity --query Account --output text
    $region = aws configure get region
    if (-not $region) { $region = "us-east-1" }
    
    $logGroupName = "/aws/sns/$region/$accountId/DirectPublishToPhoneNumber"
    
    Write-Host "  Checking log group: $logGroupName" -ForegroundColor Yellow
    
    $snsLogs = aws logs tail $logGroupName --since 5m --format short 2>&1
    
    if ($snsLogs -match "SUCCESS") {
        Write-Host "  ✅ Found successful delivery in SNS logs" -ForegroundColor Green
    } elseif ($snsLogs -match "FAILURE") {
        Write-Host "  ❌ Found delivery failure in SNS logs" -ForegroundColor Red
        Write-Host "    Check full logs with: aws logs tail $logGroupName --follow" -ForegroundColor Yellow
    } else {
        Write-Host "  ⚠️  No recent delivery logs (may still be processing)" -ForegroundColor Yellow
        Write-Host "    Wait 1-2 minutes and check manually:" -ForegroundColor Yellow
        Write-Host "    aws logs tail $logGroupName --follow" -ForegroundColor Cyan
    }
} catch {
    Write-Host "  ⚠️  Could not fetch SNS logs: $_" -ForegroundColor Yellow
    Write-Host "    Delivery logging may not be enabled" -ForegroundColor Yellow
}
Write-Host ""

# Test 4: Frontend Verification
Write-Host "[4/4] Frontend verification checklist..." -ForegroundColor Green
Write-Host ""
Write-Host "  Manual steps to verify:" -ForegroundColor Yellow
Write-Host "  1. Open: $CLOUDFRONT_URL" -ForegroundColor Cyan
Write-Host "  2. Hard refresh: Ctrl+Shift+R" -ForegroundColor Cyan
Write-Host "  3. Check Build ID in top stamp: $BUILD_ID" -ForegroundColor Cyan
Write-Host "  4. Complete Step 1 with: $COLOMBIA_PHONE" -ForegroundColor Cyan
Write-Host "  5. Click 'Send Test SMS' button" -ForegroundColor Cyan
Write-Host "  6. Check Delivery Proof panel for status" -ForegroundColor Cyan
Write-Host "  7. Verify SMS arrives on phone" -ForegroundColor Cyan
Write-Host "  8. Verify SMS content matches preview" -ForegroundColor Cyan
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VERIFICATION SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend Tests:" -ForegroundColor Yellow
Write-Host "  - Lambda invocation: Check results above"
Write-Host "  - Lambda logs: Check for success messages"
Write-Host "  - SNS delivery logs: May take 1-2 minutes"
Write-Host ""
Write-Host "Frontend Tests:" -ForegroundColor Yellow
Write-Host "  - Build ID verification: Manual"
Write-Host "  - SMS sending: Manual"
Write-Host "  - Delivery proof: Manual"
Write-Host "  - Content verification: Manual"
Write-Host ""
Write-Host "Expected Outcome:" -ForegroundColor Yellow
Write-Host "  ✅ SMS arrives at $COLOMBIA_PHONE within 30 seconds"
Write-Host "  ✅ Message content matches preview exactly"
Write-Host "  ✅ Delivery Proof panel shows SENT status"
Write-Host "  ✅ CloudWatch logs show successful delivery"
Write-Host ""
Write-Host "If SMS does NOT arrive:" -ForegroundColor Yellow
Write-Host "  1. Check SNS spend limit (must be > $0)"
Write-Host "  2. Check SNS delivery logs for failure reason"
Write-Host "  3. Verify phone number format: +573222063010"
Write-Host "  4. Check Lambda logs for errors"
Write-Host "  5. Review: Gemini3_AllSensesAI/SMS_DELIVERY_RUNBOOK.md"
Write-Host ""
Write-Host "Troubleshooting:" -ForegroundColor Yellow
Write-Host "  Runbook: Gemini3_AllSensesAI/SMS_DELIVERY_RUNBOOK.md"
Write-Host "  SNS Config: .\Gemini3_AllSensesAI\deployment\check-sns-config.ps1"
Write-Host ""

