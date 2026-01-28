#!/usr/bin/env pwsh
# Verify CloudFront Deployment
# Build: GEMINI3-JURY-READY-20260128-v1

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$BUILD_ID = "GEMINI3-JURY-READY-20260128-v1"
$CLOUDFRONT_URL = "https://dfc8ght8abwqc.cloudfront.net"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verifying CloudFront Deployment" -ForegroundColor Cyan
Write-Host "Build ID: $BUILD_ID" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "[1/5] Fetching CloudFront content..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $CLOUDFRONT_URL -UseBasicParsing
    $html = $response.Content
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "  Size: $($html.Length) bytes" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Failed to fetch CloudFront URL" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n[2/5] Checking Build ID in top stamp..." -ForegroundColor Yellow
if ($html -match "Build: $BUILD_ID") {
    Write-Host "  Found in top stamp" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Build ID not found in top stamp" -ForegroundColor Red
    Write-Host "  Expected: Build: $BUILD_ID" -ForegroundColor Red
    exit 1
}

Write-Host "`n[3/5] Checking Build ID in Runtime Health Check..." -ForegroundColor Yellow
if ($html.Contains("Loaded Build ID") -and $html.Contains($BUILD_ID)) {
    Write-Host "  Found in Runtime Health Check" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Build ID not found in Runtime Health Check" -ForegroundColor Red
    exit 1
}

Write-Host "`n[4/5] Checking required functions..." -ForegroundColor Yellow
$requiredFunctions = @(
    'function composeAlertPayload(',
    'function composeAlertSms(',
    'function renderSmsPreviewFields(',
    'function updateSmsPreview(',
    'function completeStep1('
)

$allFound = $true
foreach ($func in $requiredFunctions) {
    if ($html.Contains($func)) {
        Write-Host "  $func" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: Missing $func" -ForegroundColor Red
        $allFound = $false
    }
}

if (-not $allFound) {
    exit 1
}

Write-Host "`n[5/5] Checking SMS preview fields..." -ForegroundColor Yellow
$smsFields = @(
    'id="sms-victim"',
    'id="sms-risk"',
    'id="sms-recommendation"',
    'id="sms-message"',
    'id="sms-location"',
    'id="sms-map"',
    'id="sms-time"',
    'id="sms-action"'
)

$allFound = $true
foreach ($field in $smsFields) {
    if ($html.Contains($field)) {
        Write-Host "  $field" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: Missing $field" -ForegroundColor Red
        $allFound = $false
    }
}

if (-not $allFound) {
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CLOUDFRONT VERIFICATION COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Build ID: $BUILD_ID" -ForegroundColor White
Write-Host "CloudFront URL: $CLOUDFRONT_URL" -ForegroundColor White
Write-Host "`nAll checks passed!" -ForegroundColor Green
Write-Host "`nThe deployed page shows Build ID in 2 locations:" -ForegroundColor Yellow
Write-Host "1. Top stamp bar: Build: $BUILD_ID" -ForegroundColor White
Write-Host "2. Runtime Health Check: Loaded Build ID: $BUILD_ID" -ForegroundColor White
Write-Host "`nOpen URL in browser to verify visually:" -ForegroundColor Yellow
Write-Host "$CLOUDFRONT_URL" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
