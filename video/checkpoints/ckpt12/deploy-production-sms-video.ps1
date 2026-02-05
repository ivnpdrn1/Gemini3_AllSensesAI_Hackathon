# Deploy Production SMS Video Variant to S3 + CloudFront
# CRITICAL: Deploys to SEPARATE path to preserve baseline production build

param(
    [Parameter(Mandatory=$true)]
    [string]$BucketName,
    
    [Parameter(Mandatory=$true)]
    [string]$DistributionId,
    
    [Parameter(Mandatory=$false)]
    [string]$VideoPath = "video/index.html",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploy Production SMS Video Variant" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Validate inputs
Write-Host "[1/6] Validating inputs..." -ForegroundColor Yellow
Write-Host "  Bucket: $BucketName"
Write-Host "  Distribution: $DistributionId"
Write-Host "  Video Path: $VideoPath"
Write-Host "  Region: $Region"
Write-Host ""

# Check if source file exists
$SourceFile = "Gemini3_AllSensesAI/gemini3-guardian-production-sms-video.html"
if (-not (Test-Path $SourceFile)) {
    Write-Host "ERROR: Source file not found: $SourceFile" -ForegroundColor Red
    exit 1
}

Write-Host "[2/6] Source file found: $SourceFile" -ForegroundColor Green
Write-Host "  File size: $((Get-Item $SourceFile).Length) bytes"
Write-Host ""

# Upload to S3 with cache-busting headers
Write-Host "[3/6] Uploading to S3..." -ForegroundColor Yellow
Write-Host "  S3 Key: s3://$BucketName/$VideoPath"
Write-Host ""

try {
    aws s3 cp $SourceFile "s3://$BucketName/$VideoPath" `
        --content-type "text/html" `
        --cache-control "max-age=0, no-cache, no-store, must-revalidate" `
        --metadata-directive REPLACE `
        --region $Region
    
    if ($LASTEXITCODE -ne 0) {
        throw "S3 upload failed with exit code $LASTEXITCODE"
    }
    
    Write-Host "[3/6] Upload successful!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "ERROR: S3 upload failed: $_" -ForegroundColor Red
    exit 1
}

# Verify upload
Write-Host "[4/6] Verifying upload..." -ForegroundColor Yellow
try {
    $S3Object = aws s3api head-object `
        --bucket $BucketName `
        --key $VideoPath `
        --region $Region | ConvertFrom-Json
    
    Write-Host "  Content-Type: $($S3Object.ContentType)"
    Write-Host "  Cache-Control: $($S3Object.CacheControl)"
    Write-Host "  Last-Modified: $($S3Object.LastModified)"
    Write-Host "  ETag: $($S3Object.ETag)"
    Write-Host "[4/6] Verification successful!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "WARNING: Could not verify upload: $_" -ForegroundColor Yellow
    Write-Host ""
}

# Create CloudFront invalidation
Write-Host "[5/6] Creating CloudFront invalidation..." -ForegroundColor Yellow
Write-Host "  Path: /$VideoPath"
Write-Host ""

try {
    $InvalidationResult = aws cloudfront create-invalidation `
        --distribution-id $DistributionId `
        --paths "/$VideoPath" | ConvertFrom-Json
    
    $InvalidationId = $InvalidationResult.Invalidation.Id
    Write-Host "  Invalidation ID: $InvalidationId"
    Write-Host "  Status: $($InvalidationResult.Invalidation.Status)"
    Write-Host "[5/6] Invalidation created!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "ERROR: CloudFront invalidation failed: $_" -ForegroundColor Red
    Write-Host "  You may need to manually invalidate: /$VideoPath" -ForegroundColor Yellow
    Write-Host ""
}

# Print test URLs
Write-Host "[6/6] Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test URLs" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get CloudFront domain name
try {
    $DistributionInfo = aws cloudfront get-distribution `
        --id $DistributionId | ConvertFrom-Json
    
    $DomainName = $DistributionInfo.Distribution.DomainName
    
    Write-Host "Video Variant URL:" -ForegroundColor Yellow
    Write-Host "  https://$DomainName/$VideoPath" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Baseline Production URL (should be unchanged):" -ForegroundColor Yellow
    Write-Host "  https://$DomainName/" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "S3 Direct URL:" -ForegroundColor Yellow
    Write-Host "  https://$BucketName.s3.$Region.amazonaws.com/$VideoPath" -ForegroundColor Cyan
    Write-Host ""
} catch {
    Write-Host "Could not retrieve CloudFront domain name" -ForegroundColor Yellow
    Write-Host "  Distribution ID: $DistributionId" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Wait for CloudFront invalidation to complete (1-5 minutes)"
Write-Host "2. Test video variant URL in browser"
Write-Host "3. Verify baseline production URL still works"
Write-Host "4. Execute E2E validation using PROOF_BUNDLE.md"
Write-Host "5. If issues found, run rollback script"
Write-Host ""
Write-Host "Rollback command:" -ForegroundColor Yellow
Write-Host "  .\rollback-production-sms-video.ps1 -BucketName $BucketName -DistributionId $DistributionId" -ForegroundColor Cyan
Write-Host ""

Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host ""

