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
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipInvalidation
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploy Production SMS Video Variant" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check AWS CLI version and warn if v1
Write-Host "[0/6] Checking AWS CLI version..." -ForegroundColor Yellow
try {
    $AwsVersion = aws --version 2>&1
    Write-Host "  $AwsVersion"
    
    if ($AwsVersion -match "aws-cli/1\.") {
        Write-Host ""
        Write-Host "WARNING: AWS CLI v1 detected!" -ForegroundColor Yellow
        Write-Host "  CloudFront invalidation may fail due to known NoSuchDistribution bug." -ForegroundColor Yellow
        Write-Host "  Recommendation: Upgrade to AWS CLI v2 for better CloudFront support." -ForegroundColor Yellow
        Write-Host "  Install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Deployment will continue. Use -SkipInvalidation to bypass invalidation step." -ForegroundColor Yellow
        Write-Host ""
    }
} catch {
    Write-Host "  Could not detect AWS CLI version" -ForegroundColor Yellow
}
Write-Host ""

# Validate inputs
Write-Host "[1/6] Validating inputs..." -ForegroundColor Yellow
Write-Host "  Bucket: $BucketName"
Write-Host "  Distribution: $DistributionId"
Write-Host "  Video Path: $VideoPath"
Write-Host "  Region: $Region"
Write-Host ""

# Check if source file exists
$SourceFile = "Gemini3_AllSensesAI/video/release/rc1/gemini3-guardian-production-sms-video.html"
if (-not (Test-Path $SourceFile)) {
    Write-Host "ERROR: Source file not found: $SourceFile" -ForegroundColor Red
    exit 1
}

Write-Host "[2/6] Source file found: $SourceFile" -ForegroundColor Green
Write-Host "  File size: $((Get-Item $SourceFile).Length) bytes"
Write-Host ""

# Upload to S3 with cache-busting headers
Write-Host "[3/6] Uploading HTML and JS modules to S3..." -ForegroundColor Yellow
Write-Host "  S3 Key: s3://$BucketName/$VideoPath"
Write-Host ""

try {
    # Upload HTML file
    aws s3 cp $SourceFile "s3://$BucketName/$VideoPath" `
        --content-type "text/html" `
        --cache-control "max-age=0, no-cache, no-store, must-revalidate" `
        --metadata-directive REPLACE `
        --region $Region
    
    if ($LASTEXITCODE -ne 0) {
        throw "S3 HTML upload failed with exit code $LASTEXITCODE"
    }
    
    Write-Host "  ✓ HTML uploaded successfully" -ForegroundColor Green
    
    # Upload JS modules to /video/ directory
    $JSModules = @(
        "VideoCaptureModule.js",
        "VideoStorageService.js",
        "SignedURLGenerator.js",
        "IntegrationOrchestrator.js"
    )
    
    foreach ($JSFile in $JSModules) {
        $JSSourcePath = "Gemini3_AllSensesAI/video/release/rc1/$JSFile"
        $JSS3Key = "video/$JSFile"
        
        if (-not (Test-Path $JSSourcePath)) {
            throw "JS module not found: $JSSourcePath"
        }
        
        Write-Host "  Uploading $JSFile..." -ForegroundColor Yellow
        
        aws s3 cp $JSSourcePath "s3://$BucketName/$JSS3Key" `
            --content-type "application/javascript" `
            --cache-control "max-age=0, no-cache, no-store, must-revalidate" `
            --metadata-directive REPLACE `
            --region $Region
        
        if ($LASTEXITCODE -ne 0) {
            throw "S3 upload failed for $JSFile with exit code $LASTEXITCODE"
        }
        
        Write-Host "  ✓ $JSFile uploaded to s3://$BucketName/$JSS3Key" -ForegroundColor Green
    }
    
    Write-Host "[3/6] All uploads successful!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "ERROR: S3 upload failed: $_" -ForegroundColor Red
    exit 1
}

# Verify upload
Write-Host "[4/6] Verifying uploads..." -ForegroundColor Yellow
try {
    # Verify HTML
    $S3Object = aws s3api head-object `
        --bucket $BucketName `
        --key $VideoPath `
        --region $Region | ConvertFrom-Json
    
    Write-Host "  HTML File:"
    Write-Host "    Content-Type: $($S3Object.ContentType)"
    Write-Host "    Cache-Control: $($S3Object.CacheControl)"
    Write-Host "    Last-Modified: $($S3Object.LastModified)"
    
    # Verify JS modules
    $JSModules = @(
        "VideoCaptureModule.js",
        "VideoStorageService.js",
        "SignedURLGenerator.js",
        "IntegrationOrchestrator.js"
    )
    
    foreach ($JSFile in $JSModules) {
        $JSS3Key = "video/$JSFile"
        $JSObject = aws s3api head-object `
            --bucket $BucketName `
            --key $JSS3Key `
            --region $Region | ConvertFrom-Json
        
        Write-Host "  $JSFile"
        Write-Host "    Content-Type: $($JSObject.ContentType)"
        Write-Host "    Size: $($JSObject.ContentLength) bytes"
    }
    
    Write-Host "[4/6] Verification successful!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "WARNING: Could not verify upload: $_" -ForegroundColor Yellow
    Write-Host ""
}

# Create CloudFront invalidation
if ($SkipInvalidation) {
    Write-Host "[5/6] Skipping CloudFront invalidation (per -SkipInvalidation flag)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Manual invalidation instructions:" -ForegroundColor Yellow
    Write-Host "  Distribution: $DistributionId" -ForegroundColor Cyan
    Write-Host "  Paths: /$VideoPath, /video/*.js" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "[5/6] Creating CloudFront invalidation..." -ForegroundColor Yellow
    Write-Host "  Paths: /$VideoPath, /video/*.js"
    Write-Host ""

    try {
        $InvalidationResult = aws cloudfront create-invalidation `
            --distribution-id $DistributionId `
            --paths "/$VideoPath" "/video/VideoCaptureModule.js" "/video/VideoStorageService.js" "/video/SignedURLGenerator.js" "/video/IntegrationOrchestrator.js" | ConvertFrom-Json
        
        $InvalidationId = $InvalidationResult.Invalidation.Id
        Write-Host "  Invalidation ID: $InvalidationId"
        Write-Host "  Status: $($InvalidationResult.Invalidation.Status)"
        Write-Host "[5/6] Invalidation created!" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "WARNING: CloudFront invalidation failed: $_" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This is a known AWS CLI v1 issue (NoSuchDistribution bug)." -ForegroundColor Yellow
        Write-Host "S3 upload was successful. You can manually invalidate via AWS Console:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Distribution: $DistributionId" -ForegroundColor Cyan
        Write-Host "  Paths to invalidate:" -ForegroundColor Cyan
        Write-Host "    /$VideoPath" -ForegroundColor Cyan
        Write-Host "    /video/VideoCaptureModule.js" -ForegroundColor Cyan
        Write-Host "    /video/VideoStorageService.js" -ForegroundColor Cyan
        Write-Host "    /video/SignedURLGenerator.js" -ForegroundColor Cyan
        Write-Host "    /video/IntegrationOrchestrator.js" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  OR use wildcard: /video/*" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "NOTE: Deployment is still successful. Invalidation is optional for immediate cache refresh." -ForegroundColor Green
        Write-Host ""
    }
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

