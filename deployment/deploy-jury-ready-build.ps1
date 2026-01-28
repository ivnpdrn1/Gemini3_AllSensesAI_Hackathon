#!/usr/bin/env pwsh
# Deploy Jury-Ready Production Build
# Build: JURY-READY-20260128-v1

param(
    [string]$BucketName = "allsenses-gemini3-production",
    [string]$DistributionId = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$BUILD_ID = "GEMINI3-JURY-READY-20260128-v1"
$SOURCE_FILE = "Gemini3_AllSensesAI/gemini3-guardian-jury-ready.html"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying Jury-Ready Production Build" -ForegroundColor Cyan
Write-Host "Build ID: $BUILD_ID" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Verify source file exists
if (-not (Test-Path $SOURCE_FILE)) {
    Write-Host "ERROR: Source file not found: $SOURCE_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "[1/4] Verifying AWS credentials..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Host "  AWS Account: $($identity.Account)" -ForegroundColor Green
    Write-Host "  User/Role: $($identity.Arn)" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: AWS credentials not configured" -ForegroundColor Red
    exit 1
}

Write-Host "`n[2/4] Uploading to S3..." -ForegroundColor Yellow
try {
    aws s3 cp $SOURCE_FILE "s3://$BucketName/index.html" `
        --content-type "text/html" `
        --cache-control "no-cache, no-store, must-revalidate"
    Write-Host "  Uploaded to s3://$BucketName/index.html" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Failed to upload to S3" -ForegroundColor Red
    exit 1
}

# Get CloudFront distribution ID if not provided
if ([string]::IsNullOrEmpty($DistributionId)) {
    Write-Host "`n[3/4] Finding CloudFront distribution..." -ForegroundColor Yellow
    try {
        $distributions = aws cloudfront list-distributions --output json | ConvertFrom-Json
        $dist = $distributions.DistributionList.Items | Where-Object {
            $_.Origins.Items[0].DomainName -like "*$BucketName*"
        } | Select-Object -First 1
        
        if ($dist) {
            $DistributionId = $dist.Id
            Write-Host "  Found distribution: $DistributionId" -ForegroundColor Green
        } else {
            Write-Host "  WARNING: No CloudFront distribution found for bucket $BucketName" -ForegroundColor Yellow
            Write-Host "  Skipping invalidation step" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  WARNING: Could not query CloudFront distributions" -ForegroundColor Yellow
        Write-Host "  Skipping invalidation step" -ForegroundColor Yellow
    }
}

# Create CloudFront invalidation
if (-not [string]::IsNullOrEmpty($DistributionId)) {
    Write-Host "`n[4/4] Creating CloudFront invalidation..." -ForegroundColor Yellow
    try {
        $invalidation = aws cloudfront create-invalidation `
            --distribution-id $DistributionId `
            --paths "/*" `
            --output json | ConvertFrom-Json
        
        $invalidationId = $invalidation.Invalidation.Id
        Write-Host "  Invalidation created: $invalidationId" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Failed to create invalidation" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`n[4/4] Skipping CloudFront invalidation (no distribution ID)" -ForegroundColor Yellow
}

# Get CloudFront URL
$cloudfrontUrl = ""
if (-not [string]::IsNullOrEmpty($DistributionId)) {
    try {
        $distInfo = aws cloudfront get-distribution --id $DistributionId --output json | ConvertFrom-Json
        $cloudfrontUrl = "https://$($distInfo.Distribution.DomainName)"
    } catch {
        Write-Host "  WARNING: Could not retrieve CloudFront URL" -ForegroundColor Yellow
    }
}

# Print deployment summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Build ID: $BUILD_ID" -ForegroundColor White
Write-Host "S3 Bucket: $BucketName" -ForegroundColor White
if (-not [string]::IsNullOrEmpty($DistributionId)) {
    Write-Host "Distribution ID: $DistributionId" -ForegroundColor White
}
if (-not [string]::IsNullOrEmpty($cloudfrontUrl)) {
    Write-Host "CloudFront URL: $cloudfrontUrl" -ForegroundColor White
}
if (-not [string]::IsNullOrEmpty($invalidationId)) {
    Write-Host "Invalidation ID: $invalidationId" -ForegroundColor White
}
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Wait 2-3 minutes for CloudFront invalidation to complete" -ForegroundColor White
Write-Host "2. Open CloudFront URL in browser" -ForegroundColor White
Write-Host "3. Verify Build ID appears in both:" -ForegroundColor White
Write-Host "   - Top stamp bar (Build: $BUILD_ID)" -ForegroundColor White
Write-Host "   - Runtime Health Check panel (Loaded Build ID)" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan
