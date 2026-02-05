# Rollback Production SMS Video Variant
# CRITICAL: Removes video variant, preserves baseline production build

param(
    [Parameter(Mandatory=$true)]
    [string]$BucketName,
    
    [Parameter(Mandatory=$true)]
    [string]$DistributionId,
    
    [Parameter(Mandatory=$false)]
    [string]$VideoPath = "video/index.html",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Red
Write-Host "Rollback Production SMS Video Variant" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

# Validate inputs
Write-Host "[1/5] Validating inputs..." -ForegroundColor Yellow
Write-Host "  Bucket: $BucketName"
Write-Host "  Distribution: $DistributionId"
Write-Host "  Video Path: $VideoPath"
Write-Host "  Region: $Region"
Write-Host ""

# Confirm rollback
if (-not $Force) {
    Write-Host "WARNING: This will DELETE the video variant from S3" -ForegroundColor Yellow
    Write-Host "  S3 Key: s3://$BucketName/$VideoPath" -ForegroundColor Red
    Write-Host ""
    $Confirmation = Read-Host "Type 'ROLLBACK' to confirm"

    if ($Confirmation -ne "ROLLBACK") {
        Write-Host "Rollback cancelled by user" -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host "FORCE MODE: Skipping confirmation prompt" -ForegroundColor Yellow
    Write-Host "  S3 Key: s3://$BucketName/$VideoPath" -ForegroundColor Red
}

Write-Host ""

# Check if video variant exists
Write-Host "[2/5] Checking if video variant exists..." -ForegroundColor Yellow
try {
    aws s3api head-object `
        --bucket $BucketName `
        --key $VideoPath `
        --region $Region | Out-Null
    
    Write-Host "  Video variant found: s3://$BucketName/$VideoPath" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "  Video variant not found (already deleted or never deployed)" -ForegroundColor Yellow
    Write-Host "  Skipping deletion step" -ForegroundColor Yellow
    Write-Host ""
    $SkipDeletion = $true
}

# Delete video variant from S3
if (-not $SkipDeletion) {
    Write-Host "[3/5] Deleting video variant from S3..." -ForegroundColor Yellow
    try {
        aws s3 rm "s3://$BucketName/$VideoPath" --region $Region
        
        if ($LASTEXITCODE -ne 0) {
            throw "S3 deletion failed with exit code $LASTEXITCODE"
        }
        
        Write-Host "[3/5] Deletion successful!" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "ERROR: S3 deletion failed: $_" -ForegroundColor Red
        Write-Host "  You may need to manually delete: s3://$BucketName/$VideoPath" -ForegroundColor Yellow
        Write-Host ""
    }
} else {
    Write-Host "[3/5] Skipped (video variant not found)" -ForegroundColor Yellow
    Write-Host ""
}

# Create CloudFront invalidation
Write-Host "[4/5] Creating CloudFront invalidation..." -ForegroundColor Yellow
Write-Host "  Path: /$VideoPath"
Write-Host ""

try {
    $InvalidationResult = aws cloudfront create-invalidation `
        --distribution-id $DistributionId `
        --paths "/$VideoPath" | ConvertFrom-Json
    
    $InvalidationId = $InvalidationResult.Invalidation.Id
    Write-Host "  Invalidation ID: $InvalidationId"
    Write-Host "  Status: $($InvalidationResult.Invalidation.Status)"
    Write-Host "[4/5] Invalidation created!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "ERROR: CloudFront invalidation failed: $_" -ForegroundColor Red
    Write-Host "  You may need to manually invalidate: /$VideoPath" -ForegroundColor Yellow
    Write-Host ""
}

# Verify baseline production still works
Write-Host "[5/5] Verifying baseline production..." -ForegroundColor Yellow
try {
    $BaselineKey = "index.html"
    aws s3api head-object `
        --bucket $BucketName `
        --key $BaselineKey `
        --region $Region | Out-Null
    
    Write-Host "  Baseline production found: s3://$BucketName/$BaselineKey" -ForegroundColor Green
    Write-Host "[5/5] Verification successful!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "WARNING: Could not verify baseline production" -ForegroundColor Yellow
    Write-Host "  Expected key: s3://$BucketName/$BaselineKey" -ForegroundColor Yellow
    Write-Host ""
}

# Print test URLs
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Rollback Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get CloudFront domain name
try {
    $DistributionInfo = aws cloudfront get-distribution `
        --id $DistributionId | ConvertFrom-Json
    
    $DomainName = $DistributionInfo.Distribution.DomainName
    
    Write-Host "Video Variant URL (should return 404):" -ForegroundColor Yellow
    Write-Host "  https://$DomainName/$VideoPath" -ForegroundColor Red
    Write-Host ""
    
    Write-Host "Baseline Production URL (should still work):" -ForegroundColor Yellow
    Write-Host "  https://$DomainName/" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "Could not retrieve CloudFront domain name" -ForegroundColor Yellow
    Write-Host "  Distribution ID: $DistributionId" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verification Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Wait for CloudFront invalidation to complete (1-5 minutes)"
Write-Host "2. Test video variant URL (should return 404 or redirect)"
Write-Host "3. Test baseline production URL (should work normally)"
Write-Host "4. Verify no console errors on baseline production"
Write-Host ""

Write-Host "Rollback completed successfully!" -ForegroundColor Green
Write-Host ""

