# Test SMS Delivery - Production Verification
# Tests both US and international numbers

param(
    [Parameter(Mandatory=$true)]
    [string]$FunctionUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$USPhone = "+1234567890",
    
    [Parameter(Mandatory=$false)]
    [string]$ColombiaPhone = "+573222063010"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SMS Delivery Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Function URL: $FunctionUrl" -ForegroundColor Yellow
Write-Host ""

# Test 1: US Number
Write-Host "[TEST 1] US Number: $USPhone" -ForegroundColor Yellow

$payload1 = @{
    action = "EMERGENCY_ALERT"
    victimName = "Test User"
    phoneNumber = $USPhone
    emergencyMessage = "🚨 TEST ALERT from AllSenses AI Guardian`n`nVictim: Test User`nType: Manual Test`nTime: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`nThis is a test message. If you receive this, SMS delivery is working correctly."
    detectionType = "MANUAL_TEST"
    timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    location = @{
        lat = 25.7617
        lon = -80.1918
        placeName = "Miami, FL"
        mapLink = "https://maps.google.com/?q=25.7617,-80.1918"
    }
} | ConvertTo-Json -Depth 10

try {
    $response1 = Invoke-RestMethod -Uri $FunctionUrl -Method Post -Body $payload1 -ContentType "application/json"
    Write-Host "  ✅ SUCCESS" -ForegroundColor Green
    Write-Host "  Message ID: $($response1.smsMessageId)" -ForegroundColor Green
    Write-Host "  Status: $($response1.status)" -ForegroundColor Green
    Write-Host "  Phone: $($response1.phoneNumber)" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "  ❌ FAILED" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}

# Wait 5 seconds
Write-Host "Waiting 5 seconds before next test..." -ForegroundColor Gray
Start-Sleep -Seconds 5

# Test 2: Colombia Number
Write-Host "[TEST 2] Colombia Number: $ColombiaPhone" -ForegroundColor Yellow

$payload2 = @{
    action = "EMERGENCY_ALERT"
    victimName = "Test User"
    phoneNumber = $ColombiaPhone
    emergencyMessage = "🚨 TEST ALERT from AllSenses AI Guardian`n`nVictim: Test User`nType: Manual Test`nTime: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`nThis is a test message. If you receive this, SMS delivery is working correctly."
    detectionType = "MANUAL_TEST"
    timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    location = @{
        lat = 4.7110
        lon = -74.0721
        placeName = "Bogota, Colombia"
        mapLink = "https://maps.google.com/?q=4.7110,-74.0721"
    }
} | ConvertTo-Json -Depth 10

try {
    $response2 = Invoke-RestMethod -Uri $FunctionUrl -Method Post -Body $payload2 -ContentType "application/json"
    Write-Host "  ✅ SUCCESS" -ForegroundColor Green
    Write-Host "  Message ID: $($response2.smsMessageId)" -ForegroundColor Green
    Write-Host "  Status: $($response2.status)" -ForegroundColor Green
    Write-Host "  Phone: $($response2.phoneNumber)" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "  ❌ FAILED" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Check your phones for SMS delivery" -ForegroundColor White
Write-Host "  2. Verify message format is correct" -ForegroundColor White
Write-Host "  3. Check Lambda logs for any errors:" -ForegroundColor White
Write-Host "     aws logs tail /aws/lambda/allsenses-sms-production --follow" -ForegroundColor Gray
Write-Host ""
