#!/usr/bin/env pwsh
<#
.SYNOPSIS
    SNS Preflight Check for Colombia SMS
    
.DESCRIPTION
    Validates SNS configuration before deployment:
    - Spend limit > $0
    - Default SMS type
    - Delivery status logging (optional)
    - Region configuration
    
.NOTES
    Run this before deploying to catch configuration issues early
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$REGION = "us-east-1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SNS Preflight Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# Check 1: SNS Spend Limit
# ============================================================
Write-Host "[1] Checking SNS spend limit..." -ForegroundColor Yellow

try {
    $snsAttrs = aws sns get-sms-attributes --region $REGION | ConvertFrom-Json
    
    $spendLimit = $snsAttrs.attributes.'MonthlySpendLimit'
    
    if ($spendLimit -eq "0" -or $spendLimit -eq "0.00" -or $spendLimit -eq $null) {
        Write-Host "  FAIL: SNS monthly spend limit is `$0 or not set" -ForegroundColor Red
        Write-Host ""
        Write-Host "  FIX:" -ForegroundColor Yellow
        Write-Host "  1. Go to AWS Console -> SNS -> Text messaging (SMS) -> Preferences" -ForegroundColor White
        Write-Host "  2. Set 'Account spend limit' to `$5 or `$10" -ForegroundColor White
        Write-Host "  3. Click 'Save changes'" -ForegroundColor White
        Write-Host ""
        $PASS_SPEND_LIMIT = $false
    } else {
        Write-Host "  PASS: SNS spend limit = `$$spendLimit" -ForegroundColor Green
        $PASS_SPEND_LIMIT = $true
    }
} catch {
    Write-Host "  ERROR: Could not check SNS spend limit" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Gray
    $PASS_SPEND_LIMIT = $false
}

Write-Host ""

# ============================================================
# Check 2: Default SMS Type
# ============================================================
Write-Host "[2] Checking default SMS type..." -ForegroundColor Yellow

try {
    $defaultSmsType = $snsAttrs.attributes.'DefaultSMSType'
    
    if ($defaultSmsType -eq "Transactional") {
        Write-Host "  PASS: Default SMS type = Transactional (recommended for emergency alerts)" -ForegroundColor Green
        $PASS_SMS_TYPE = $true
    } elseif ($defaultSmsType -eq "Promotional") {
        Write-Host "  WARNING: Default SMS type = Promotional (may have lower priority)" -ForegroundColor Yellow
        Write-Host "  Consider changing to 'Transactional' for emergency alerts" -ForegroundColor Yellow
        $PASS_SMS_TYPE = $true
    } else {
        Write-Host "  INFO: Default SMS type = $defaultSmsType" -ForegroundColor Gray
        $PASS_SMS_TYPE = $true
    }
} catch {
    Write-Host "  WARNING: Could not check default SMS type" -ForegroundColor Yellow
    $PASS_SMS_TYPE = $true
}

Write-Host ""

# ============================================================
# Check 3: Delivery Status Logging
# ============================================================
Write-Host "[3] Checking delivery status logging..." -ForegroundColor Yellow

try {
    $deliveryStatusIAMRole = $snsAttrs.attributes.'DeliveryStatusIAMRole'
    $deliveryStatusSuccessSamplingRate = $snsAttrs.attributes.'DeliveryStatusSuccessSamplingRate'
    
    if ($deliveryStatusIAMRole) {
        Write-Host "  INFO: Delivery status logging enabled" -ForegroundColor Green
        Write-Host "  IAM Role: $deliveryStatusIAMRole" -ForegroundColor Gray
        Write-Host "  Success sampling rate: $deliveryStatusSuccessSamplingRate%" -ForegroundColor Gray
    } else {
        Write-Host "  INFO: Delivery status logging not enabled (optional)" -ForegroundColor Gray
        Write-Host "  This is optional but recommended for production monitoring" -ForegroundColor Gray
    }
} catch {
    Write-Host "  INFO: Delivery status logging not configured (optional)" -ForegroundColor Gray
}

Write-Host ""

# ============================================================
# Check 4: Region Configuration
# ============================================================
Write-Host "[4] Checking region configuration..." -ForegroundColor Yellow

Write-Host "  Region: $REGION" -ForegroundColor Green
Write-Host "  Lambda and SNS must be in the same region" -ForegroundColor Gray

Write-Host ""

# ============================================================
# Check 5: SMS Sandbox Status (if applicable)
# ============================================================
Write-Host "[5] Checking SMS sandbox status..." -ForegroundColor Yellow

try {
    # Try to get sandbox status (this may not be available in all regions/accounts)
    $sandboxStatus = aws sns get-sms-sandbox-account-status --region $REGION 2>$null | ConvertFrom-Json
    
    if ($sandboxStatus.IsInSandbox -eq $true) {
        Write-Host "  WARNING: Account is in SMS sandbox mode" -ForegroundColor Yellow
        Write-Host "  You can only send SMS to verified phone numbers" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  To exit sandbox:" -ForegroundColor Yellow
        Write-Host "  1. Go to AWS Console -> SNS -> Text messaging (SMS) -> Sandbox" -ForegroundColor White
        Write-Host "  2. Request production access" -ForegroundColor White
        Write-Host "  3. Provide use case details" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "  PASS: Account is NOT in SMS sandbox mode" -ForegroundColor Green
    }
} catch {
    Write-Host "  INFO: Could not check SMS sandbox status (may not be applicable)" -ForegroundColor Gray
}

Write-Host ""

# ============================================================
# Check 6: E.164 Phone Number Validation
# ============================================================
Write-Host "[6] E.164 phone number format..." -ForegroundColor Yellow

Write-Host "  Colombia numbers must be in E.164 format:" -ForegroundColor White
Write-Host "  - Start with +" -ForegroundColor Gray
Write-Host "  - Country code: 57" -ForegroundColor Gray
Write-Host "  - 10 digits (mobile)" -ForegroundColor Gray
Write-Host "  - Example: +573222063010" -ForegroundColor Gray
Write-Host ""
Write-Host "  Pattern: ^\+57\d{10}$" -ForegroundColor Gray

Write-Host ""

# ============================================================
# Summary
# ============================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PREFLIGHT CHECK SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($PASS_SPEND_LIMIT -and $PASS_SMS_TYPE) {
    Write-Host "PASS: All critical checks passed" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can proceed with deployment:" -ForegroundColor White
    Write-Host "  .\Gemini3_AllSensesAI\deployment\deploy-colombia-sms-fix-v3.ps1" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "FAIL: Some critical checks failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please fix the issues above before deploying" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "Additional Information:" -ForegroundColor White
Write-Host "- Region: $REGION" -ForegroundColor Gray
Write-Host "- Spend Limit: `$$spendLimit" -ForegroundColor Gray
Write-Host "- Default SMS Type: $defaultSmsType" -ForegroundColor Gray
Write-Host ""

