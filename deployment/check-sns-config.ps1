# Check SNS Configuration for International SMS
# Run this BEFORE deploying Lambda

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SNS Configuration Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allChecks = @()

# Check 1: SNS Spend Limit
Write-Host "[1/5] Checking SNS spend limit..." -ForegroundColor Yellow
try {
    $snsAttrs = aws sns get-sms-attributes --output json | ConvertFrom-Json
    $spendLimit = $snsAttrs.attributes.MonthlySpendLimit
    
    if ($spendLimit -eq "0" -or $spendLimit -eq "0.00") {
        Write-Host "  ❌ CRITICAL: Monthly spend limit is $0" -ForegroundColor Red
        Write-Host "     SMS will NOT be sent!" -ForegroundColor Red
        Write-Host "     Fix: AWS Console → SNS → Text messaging (SMS) → Preferences" -ForegroundColor Yellow
        Write-Host "     Set 'Account spend limit' to $5 or $10" -ForegroundColor Yellow
        $allChecks += @{name="Spend Limit"; status="FAIL"; critical=$true}
    } else {
        Write-Host "  ✅ Spend limit: $$spendLimit" -ForegroundColor Green
        $allChecks += @{name="Spend Limit"; status="PASS"; critical=$true}
    }
} catch {
    Write-Host "  ⚠️  Could not check spend limit" -ForegroundColor Yellow
    $allChecks += @{name="Spend Limit"; status="UNKNOWN"; critical=$true}
}
Write-Host ""

# Check 2: Default SMS Type
Write-Host "[2/5] Checking default SMS type..." -ForegroundColor Yellow
try {
    $smsType = $snsAttrs.attributes.DefaultSMSType
    
    if ($smsType -eq "Transactional") {
        Write-Host "  ✅ SMS Type: Transactional" -ForegroundColor Green
        $allChecks += @{name="SMS Type"; status="PASS"; critical=$false}
    } else {
        Write-Host "  ⚠️  SMS Type: $smsType (Transactional recommended)" -ForegroundColor Yellow
        $allChecks += @{name="SMS Type"; status="WARN"; critical=$false}
    }
} catch {
    Write-Host "  ⚠️  Could not check SMS type" -ForegroundColor Yellow
    $allChecks += @{name="SMS Type"; status="UNKNOWN"; critical=$false}
}
Write-Host ""

# Check 3: Delivery Status Logging
Write-Host "[3/5] Checking delivery status logging..." -ForegroundColor Yellow
try {
    $accountId = aws sts get-caller-identity --query Account --output text
    $region = aws configure get region
    if (-not $region) { $region = "us-east-1" }
    
    $logGroupName = "/aws/sns/$region/$accountId/DirectPublishToPhoneNumber"
    $logGroupExists = aws logs describe-log-groups --log-group-name-prefix $logGroupName --output json 2>$null | ConvertFrom-Json
    
    if ($logGroupExists.logGroups.Count -gt 0) {
        Write-Host "  ✅ Delivery logging enabled" -ForegroundColor Green
        $allChecks += @{name="Delivery Logging"; status="PASS"; critical=$false}
    } else {
        Write-Host "  ⚠️  Delivery logging NOT enabled" -ForegroundColor Yellow
        Write-Host "     Recommended: Enable for debugging" -ForegroundColor Yellow
        Write-Host "     Fix: AWS Console → SNS → Text messaging (SMS) → Delivery status logging" -ForegroundColor Yellow
        $allChecks += @{name="Delivery Logging"; status="WARN"; critical=$false}
    }
} catch {
    Write-Host "  ⚠️  Could not check delivery logging" -ForegroundColor Yellow
    $allChecks += @{name="Delivery Logging"; status="UNKNOWN"; critical=$false}
}
Write-Host ""

# Check 4: Lambda Execution Role
Write-Host "[4/5] Checking Lambda execution role..." -ForegroundColor Yellow
try {
    $roleName = "gemini3-sms-sender-prod-role"
    $roleExists = aws iam get-role --role-name $roleName 2>$null
    
    if ($roleExists) {
        Write-Host "  ✅ Lambda role exists" -ForegroundColor Green
        $allChecks += @{name="Lambda Role"; status="PASS"; critical=$false}
    } else {
        Write-Host "  ℹ️  Lambda role will be created during deployment" -ForegroundColor Cyan
        $allChecks += @{name="Lambda Role"; status="INFO"; critical=$false}
    }
} catch {
    Write-Host "  ℹ️  Lambda role will be created during deployment" -ForegroundColor Cyan
    $allChecks += @{name="Lambda Role"; status="INFO"; critical=$false}
}
Write-Host ""

# Check 5: AWS CLI Configuration
Write-Host "[5/5] Checking AWS CLI configuration..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Host "  ✅ AWS Account: $($identity.Account)" -ForegroundColor Green
    Write-Host "  ✅ User/Role: $($identity.Arn)" -ForegroundColor Green
    $allChecks += @{name="AWS CLI"; status="PASS"; critical=$true}
} catch {
    Write-Host "  ❌ AWS CLI not configured" -ForegroundColor Red
    $allChecks += @{name="AWS CLI"; status="FAIL"; critical=$true}
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$criticalFails = ($allChecks | Where-Object { $_.critical -and $_.status -eq "FAIL" }).Count
$warnings = ($allChecks | Where-Object { $_.status -eq "WARN" }).Count
$passes = ($allChecks | Where-Object { $_.status -eq "PASS" }).Count

Write-Host "Passed: $passes" -ForegroundColor Green
Write-Host "Warnings: $warnings" -ForegroundColor Yellow
Write-Host "Critical Failures: $criticalFails" -ForegroundColor $(if ($criticalFails -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($criticalFails -gt 0) {
    Write-Host "❌ CRITICAL ISSUES FOUND" -ForegroundColor Red
    Write-Host ""
    Write-Host "You MUST fix these issues before deploying:" -ForegroundColor Yellow
    $allChecks | Where-Object { $_.critical -and $_.status -eq "FAIL" } | ForEach-Object {
        Write-Host "  - $($_.name)" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Most common fix:" -ForegroundColor Yellow
    Write-Host "  1. Go to AWS Console → SNS → Text messaging (SMS) → Preferences" -ForegroundColor Cyan
    Write-Host "  2. Click 'Edit' on 'Account spend limit'" -ForegroundColor Cyan
    Write-Host "  3. Set to $5 or $10" -ForegroundColor Cyan
    Write-Host "  4. Save changes" -ForegroundColor Cyan
    Write-Host "  5. Wait 1-2 minutes" -ForegroundColor Cyan
    Write-Host "  6. Run this script again" -ForegroundColor Cyan
    Write-Host ""
    exit 1
} else {
    Write-Host "✅ ALL CRITICAL CHECKS PASSED" -ForegroundColor Green
    Write-Host ""
    if ($warnings -gt 0) {
        Write-Host "Warnings found (non-blocking):" -ForegroundColor Yellow
        $allChecks | Where-Object { $_.status -eq "WARN" } | ForEach-Object {
            Write-Host "  - $($_.name)" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    Write-Host "You can proceed with deployment:" -ForegroundColor Green
    Write-Host "  .\Gemini3_AllSensesAI\deployment\deploy-sms-backend.ps1" -ForegroundColor Cyan
    Write-Host ""
}
