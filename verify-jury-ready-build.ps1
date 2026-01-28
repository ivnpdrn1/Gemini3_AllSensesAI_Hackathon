#!/usr/bin/env pwsh
# Verify Jury-Ready Build
# Build: JURY-READY-20260128-v1

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$BUILD_ID = "JURY-READY-20260128-v1"
$HTML_FILE = "Gemini3_AllSensesAI/jury-ready-production.html"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verifying Jury-Ready Build" -ForegroundColor Cyan
Write-Host "Build ID: $BUILD_ID" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check file exists
if (-not (Test-Path $HTML_FILE)) {
    Write-Host "ERROR: Build file not found: $HTML_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "[1/8] File exists..." -ForegroundColor Yellow
$fileSize = (Get-Item $HTML_FILE).Length
Write-Host "  Size: $fileSize bytes ($([math]::Round($fileSize/1KB, 1)) KB)" -ForegroundColor Green

# Read file content
$html = Get-Content $HTML_FILE -Raw -Encoding UTF8

Write-Host "`n[2/8] Checking Build ID in top stamp..." -ForegroundColor Yellow
if ($html -match "Build: $BUILD_ID") {
    Write-Host "  Found in top stamp" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Build ID not found in top stamp" -ForegroundColor Red
    exit 1
}

Write-Host "`n[3/8] Checking Build ID in Runtime Health Check..." -ForegroundColor Yellow
if ($html -match "Loaded Build ID") {
    Write-Host "  Found in Runtime Health Check" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Build ID not found in Runtime Health Check" -ForegroundColor Red
    exit 1
}

Write-Host "`n[4/8] Checking required functions..." -ForegroundColor Yellow
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

Write-Host "`n[5/8] Checking SMS preview fields..." -ForegroundColor Yellow
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

Write-Host "`n[6/8] Checking Step 1 button configuration..." -ForegroundColor Yellow
if ($html -match 'type="button".*onclick="completeStep1\(\)"') {
    Write-Host "  Button is type='button'" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Step 1 button not configured correctly" -ForegroundColor Red
    exit 1
}

Write-Host "`n[7/8] Checking configurable keywords UI..." -ForegroundColor Yellow
if ($html -match 'class="keywords-config"') {
    Write-Host "  Keywords UI present" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Keywords UI missing" -ForegroundColor Red
    exit 1
}

Write-Host "`n[8/8] Checking build validation script..." -ForegroundColor Yellow
if ($html -match '\[BUILD-VALIDATION\]') {
    Write-Host "  Build validation script present" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Build validation script missing" -ForegroundColor Red
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "VERIFICATION COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Build ID: $BUILD_ID" -ForegroundColor White
Write-Host "File: $HTML_FILE" -ForegroundColor White
Write-Host "Size: $([math]::Round($fileSize/1KB, 1)) KB" -ForegroundColor White
Write-Host "`nAll checks passed!" -ForegroundColor Green
Write-Host "`nNext step: Deploy with deploy-jury-ready-build.ps1" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan
