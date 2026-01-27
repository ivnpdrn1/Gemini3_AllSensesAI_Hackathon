# Deploy Gemini Static Demo to S3 + CloudFront
# Simple deployment without Lambda backend

param(
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Gemini Static Demo Deployment" -ForegroundColor Cyan
Write-Host "S3 + CloudFront (Client-Side Demo)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Generate unique bucket name
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$bucketName = "allsensesai-gemini-demo-$timestamp"

Write-Host "[1/5] Creating S3 bucket..." -ForegroundColor Yellow
try {
    aws s3 mb "s3://$bucketName" --region $Region
    Write-Host "  OK Bucket created: $bucketName" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Failed to create bucket" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/5] Configuring bucket for website hosting..." -ForegroundColor Yellow
try {
    aws s3 website "s3://$bucketName" --index-document index.html --error-document index.html
    Write-Host "  OK Website hosting enabled" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Failed to configure website hosting" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[3/5] Setting bucket policy for public access..." -ForegroundColor Yellow
$policy = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$bucketName/*"
        }
    ]
}
"@

$policy | Out-File -FilePath "deployment/bucket-policy.json" -Encoding UTF8
try {
    aws s3api put-bucket-policy --bucket $bucketName --policy file://deployment/bucket-policy.json
    Write-Host "  OK Bucket policy set" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Failed to set bucket policy" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[4/5] Uploading demo UI..." -ForegroundColor Yellow
try {
    # Use the local demo HTML (client-side only)
    aws s3 cp demo/gemini-emergency-demo.html "s3://$bucketName/index.html" --content-type "text/html"
    Write-Host "  OK UI uploaded" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Failed to upload UI" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[5/5] Getting S3 website URL..." -ForegroundColor Yellow
$websiteUrl = "http://$bucketName.s3-website-$Region.amazonaws.com"
Write-Host "  S3 Website URL: $websiteUrl" -ForegroundColor Cyan

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Demo URL (HTTP):" -ForegroundColor Cyan
Write-Host "  $websiteUrl" -ForegroundColor White
Write-Host ""
Write-Host "Note: This is a client-side demo with mock Gemini responses." -ForegroundColor Yellow
Write-Host "For production with real Gemini API, use CloudFront + Lambda deployment." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Open the URL in your browser" -ForegroundColor White
Write-Host "  2. Test with sample emergency transcripts" -ForegroundColor White
Write-Host "  3. Demo will use keyword matching (no real API calls)" -ForegroundColor White
Write-Host ""

# Save deployment info
$deploymentInfo = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    bucketName = $bucketName
    region = $Region
    websiteUrl = $websiteUrl
    type = "static-demo"
}

$deploymentInfo | ConvertTo-Json | Out-File "deployment/static-deployment-info.json" -Encoding UTF8
Write-Host "Deployment info saved to: deployment/static-deployment-info.json" -ForegroundColor Cyan
