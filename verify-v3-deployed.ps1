#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Verify v3 is deployed to CloudFront
    
.DESCRIPTION
    Checks if the CloudFront site is serving the v3 build with SMS functions
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$BUILD_ID = "GEMINI3-JURY-READY-VIDEO-SMS-20260128-v3"
$CF_STACK_NAME = "gemini3-jury-ready-cf"
$REGION = "us-east-1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "v3 Deployment Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get CloudFront URL
Write-Host "[1] Getting CloudFront URL..." -ForegroundColor Yellow

try {
    $cfOutputs = aws cloudformation describe-stacks `
        --stack-name $CF_STACK_NAME `
        --region $REGION `
        --query "Stacks[0].Outputs" | ConvertFrom-Json
    
    $cloudfrontUrl = ($cfOutputs | Where-Object { $_.OutputKey -eq "CloudFrontURL" }).OutputValue
    
    if (-not $cloudfrontUrl) {
        Write-Host "ERROR: Could not get CloudFront URL" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  CloudFront URL: $cloudfrontUrl" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Could not get CloudFront info" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Gray
    exit 1
}

Write-Host ""

# Fetch HTML from CloudFront
Write-Host "[2] Fetching HTML from CloudFront..." -ForegroundColor Yellow
Write-Host "  Adding cache-busting query parameter..." -ForegroundColor Gray

$cacheBuster = (Get-Date).Ticks
$testUrl = "$cloudfrontUrl/?cb=$cacheBuster"

try {
    $response = Invoke-WebRequest -Uri $testUrl -UseBasicParsing
    $html = $response.Content
    
    Write-Host "  HTML fetched successfully ($($html.Length) bytes)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Could not fetch HTML from CloudFront" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Gray
    exit 1
}

Write-Host ""

# Check Build ID
Write-Host "[3] Checking Build ID..." -ForegroundColor Yellow

$buildIdMatches = ([regex]::Matches($html, [regex]::Escape($BUILD_ID))).Count

if ($buildIdMatches -ge 2) {
    Write-Host "  Build ID found: $BUILD_ID ($buildIdMatches occurrences)" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Build ID not found or insufficient occurrences" -ForegroundColor Red
    Write-Host "  Expected: $BUILD_ID" -ForegroundColor Yellow
    Write-Host "  Found: $buildIdMatches occurrences" -ForegroundColor Yellow
    
    # Try to find what build ID is present
    if ($html -match 'Build: (GEMINI3-[A-Z0-9-]+)') {
        Write-Host "  Detected Build ID: $($Matches[1])" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "DIAGNOSIS: CloudFront is serving OLD HTML (v1, not v3)" -ForegroundColor Red
    Write-Host ""
    Write-Host "FIXES:" -ForegroundColor Yellow
    Write-Host "1. Run deployment script again:" -ForegroundColor White
    Write-Host "   .\Gemini3_AllSensesAI\deployment\deploy-v3-complete.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Wait 5 minutes for CDN propagation" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Clear browser cache and test in INCOGNITO" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host ""

# Check SMS Functions
Write-Host "[4] Checking SMS functions..." -ForegroundColor Yellow

$checks = @{
    "async function sendSms" = $false
    "smsDeliveryProofPanel" = $false
    "NO RISK GATING" = $false
    "function sendTestSms" = $false
    "SMS_API_URL" = $false
}

foreach ($check in $checks.Keys) {
    if ($html -match [regex]::Escape($check)) {
        $checks[$check] = $true
        Write-Host "  $check - FOUND" -ForegroundColor Green
    } else {
        Write-Host "  $check - MISSING" -ForegroundColor Red
    }
}

$allChecksPass = ($checks.Values | Where-Object { $_ -eq $false }).Count -eq 0

Write-Host ""

# Check Step 5 Status Message
Write-Host "[5] Checking Step 5 status message..." -ForegroundColor Yellow

if ($html -match 'Ready to send alert \(complete Steps 1-4 first\)') {
    Write-Host "  Initial status message - CORRECT" -ForegroundColor Green
} else {
    Write-Host "  Initial status message - INCORRECT" -ForegroundColor Red
}

if ($html -match 'Waiting for threat analysis') {
    Write-Host "  WARNING: 'Waiting for threat analysis' text found" -ForegroundColor Yellow
    Write-Host "  This should only appear temporarily during analysis" -ForegroundColor Gray
}

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VERIFICATION SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($allChecksPass) {
    Write-Host "STATUS: v3 DEPLOYED SUCCESSFULLY" -ForegroundColor Green
    Write-Host ""
    Write-Host "CloudFront URL: $cloudfrontUrl" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "1. Open URL in INCOGNITO window" -ForegroundColor White
    Write-Host "2. Verify Build ID shows: $BUILD_ID" -ForegroundColor White
    Write-Host "3. Complete Steps 1-4" -ForegroundColor White
    Write-Host "4. Verify Step 5 status updates correctly" -ForegroundColor White
    Write-Host "5. Test SMS delivery to Colombia number" -ForegroundColor White
} else {
    Write-Host "STATUS: v3 NOT FULLY DEPLOYED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Some checks failed. Run deployment script:" -ForegroundColor Yellow
    Write-Host ".\Gemini3_AllSensesAI\deployment\deploy-v3-complete.ps1" -ForegroundColor Gray
}

Write-Host ""
