# Deploy Vision MVP to S3
# Build: GEMINI3-VISION-MVP-20260127

param(
    [string]$BucketName = "allsenses-gemini3-demo",
    [switch]$DryRun = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Vision MVP Deployment Script" -ForegroundColor Cyan
Write-Host "Build: GEMINI3-VISION-MVP-20260127" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if AWS CLI is available
try {
    $awsVersion = aws --version 2>&1
    Write-Host "[CHECK] AWS CLI found: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] AWS CLI not found. Please install AWS CLI first." -ForegroundColor Red
    exit 1
}

# Check if file exists
$htmlFile = "gemini3-guardian-vision-mvp.html"
if (-not (Test-Path $htmlFile)) {
    Write-Host "[ERROR] File not found: $htmlFile" -ForegroundColor Red
    Write-Host "[ERROR] Please run this script from the Gemini3_AllSensesAI directory" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Deploying file: $htmlFile" -ForegroundColor Yellow
Write-Host "[INFO] Target bucket: $BucketName" -ForegroundColor Yellow
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY RUN] Would upload $htmlFile to s3://$BucketName/index.html" -ForegroundColor Magenta
    Write-Host "[DRY RUN] Would set Content-Type: text/html" -ForegroundColor Magenta
    Write-Host "[DRY RUN] Would set Cache-Control: no-cache" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "[DRY RUN] No actual changes made" -ForegroundColor Magenta
    exit 0
}

# Upload to S3
Write-Host "[DEPLOY] Uploading to S3..." -ForegroundColor Yellow

try {
    aws s3 cp $htmlFile "s3://$BucketName/index.html" `
        --content-type "text/html" `
        --cache-control "no-cache, no-store, must-revalidate" `
        --metadata "build=GEMINI3-VISION-MVP-20260127,feature=vision-mvp"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] File uploaded successfully!" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Upload failed with exit code: $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[ERROR] Upload failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get CloudFront distribution URL if available
Write-Host "[INFO] Checking for CloudFront distribution..." -ForegroundColor Yellow

try {
    $distributions = aws cloudfront list-distributions --query "DistributionList.Items[?Origins.Items[?DomainName=='$BucketName.s3.amazonaws.com']].{Id:Id,DomainName:DomainName,Status:Status}" --output json | ConvertFrom-Json
    
    if ($distributions -and $distributions.Count -gt 0) {
        Write-Host "[INFO] Found CloudFront distribution(s):" -ForegroundColor Green
        foreach ($dist in $distributions) {
            Write-Host "  - Distribution ID: $($dist.Id)" -ForegroundColor Cyan
            Write-Host "  - Domain: $($dist.DomainName)" -ForegroundColor Cyan
            Write-Host "  - Status: $($dist.Status)" -ForegroundColor Cyan
            Write-Host "  - URL: https://$($dist.DomainName)" -ForegroundColor Green
            Write-Host ""
        }
        
        Write-Host "[INFO] CloudFront cache may take 5-15 minutes to update" -ForegroundColor Yellow
        Write-Host "[INFO] To invalidate cache immediately, run:" -ForegroundColor Yellow
        Write-Host "  aws cloudfront create-invalidation --distribution-id <ID> --paths '/*'" -ForegroundColor Cyan
    } else {
        Write-Host "[INFO] No CloudFront distribution found for this bucket" -ForegroundColor Yellow
        Write-Host "[INFO] Direct S3 URL: http://$BucketName.s3-website-us-east-1.amazonaws.com" -ForegroundColor Cyan
    }
} catch {
    Write-Host "[WARN] Could not check CloudFront distributions: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Validation Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Open the deployed URL in a browser" -ForegroundColor White
Write-Host "2. Verify build stamp shows: GEMINI3-VISION-MVP-20260127" -ForegroundColor White
Write-Host "3. Complete Steps 1-2 (Config + Location)" -ForegroundColor White
Write-Host "4. Check Step 4 - Vision panel should show 'Standby' state" -ForegroundColor White
Write-Host "5. Start Step 3 and say 'emergency' or 'help'" -ForegroundColor White
Write-Host "6. Verify Vision panel transitions: Standby -> Capturing -> Analyzing -> Complete" -ForegroundColor White
Write-Host "7. Check completed state shows: thumbnails + findings + confidence" -ForegroundColor White
Write-Host "8. Click 'Reset Emergency State'" -ForegroundColor White
Write-Host "9. Verify Vision panel returns to Standby with placeholders" -ForegroundColor White
Write-Host ""
Write-Host "[SUCCESS] Deployment script complete!" -ForegroundColor Green
