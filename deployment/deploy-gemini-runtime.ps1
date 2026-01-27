# Deploy Gemini Runtime to CloudFront + Lambda
# One-command deployment for jury demonstrations

param(
    [string]$StackName = "allsensesai-gemini-runtime",
    [string]$Region = "us-east-1",
    [switch]$SkipApiKeySetup
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AllSensesAI Gemini Runtime Deployment" -ForegroundColor Cyan
Write-Host "CloudFront + Lambda Function URL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check prerequisites
Write-Host "[1/8] Checking prerequisites..." -ForegroundColor Yellow

# Check AWS CLI
try {
    $awsVersion = aws --version 2>&1
    Write-Host "  OK AWS CLI: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: AWS CLI not found. Install from https://aws.amazon.com/cli/" -ForegroundColor Red
    exit 1
}

# Check Python
try {
    $pythonVersion = python --version 2>&1
    Write-Host "  OK Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Python not found. Install Python 3.11+" -ForegroundColor Red
    exit 1
}

# Check .env file
if (-not (Test-Path ".env")) {
    Write-Host "  ERROR: .env file not found. Create it with GOOGLE_GEMINI_API_KEY" -ForegroundColor Red
    exit 1
}

# Load API key from .env
$apiKey = Get-Content .env | Where-Object { $_ -match "^GOOGLE_GEMINI_API_KEY=" } | ForEach-Object { $_.Split('=')[1].Trim() }
if (-not $apiKey) {
    Write-Host "  ERROR: GOOGLE_GEMINI_API_KEY not found in .env" -ForegroundColor Red
    exit 1
}
Write-Host "  OK API key loaded from .env" -ForegroundColor Green

# Step 2: Store API key in Parameter Store
if (-not $SkipApiKeySetup) {
    Write-Host ""
    Write-Host "[2/8] Storing API key in Parameter Store..." -ForegroundColor Yellow
    
    try {
        aws ssm put-parameter `
            --name "/allsensesai/gemini/api-key" `
            --value "$apiKey" `
            --type "SecureString" `
            --overwrite `
            --region $Region 2>&1 | Out-Null
        
        Write-Host "  OK API key stored securely" -ForegroundColor Green
    } catch {
        Write-Host "  WARNING: Parameter may already exist (this is OK)" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "[2/8] Skipping API key setup (--SkipApiKeySetup)" -ForegroundColor Yellow
}

# Step 3: Package Lambda function
Write-Host ""
Write-Host "[3/8] Packaging Lambda function..." -ForegroundColor Yellow

$lambdaDir = "deployment/lambda"
$packageDir = "deployment/lambda-package"
$zipFile = "deployment/lambda-package.zip"

# Create package directory
if (Test-Path $packageDir) {
    Remove-Item -Recurse -Force $packageDir
}
New-Item -ItemType Directory -Path $packageDir | Out-Null

# Copy Lambda handler
Copy-Item "$lambdaDir/gemini_handler.py" "$packageDir/"

# Copy Gemini client
Copy-Item "src/gemini/client.py" "$packageDir/"

# Install dependencies
Write-Host "  Installing dependencies..." -ForegroundColor Cyan
pip install --target $packageDir google-generativeai python-dotenv boto3 -q

# Create zip file
Write-Host "  Creating deployment package..." -ForegroundColor Cyan
if (Test-Path $zipFile) {
    Remove-Item $zipFile
}

# Use PowerShell compression
Compress-Archive -Path "$packageDir/*" -DestinationPath $zipFile -Force

$zipSize = (Get-Item $zipFile).Length / 1MB
Write-Host "  OK Package created: $([math]::Round($zipSize, 2)) MB" -ForegroundColor Green

# Step 4: Deploy CloudFormation stack
Write-Host ""
Write-Host "[4/8] Deploying CloudFormation stack..." -ForegroundColor Yellow

try {
    aws cloudformation deploy `
        --template-file deployment/gemini-runtime-cloudfront.yaml `
        --stack-name $StackName `
        --capabilities CAPABILITY_IAM `
        --region $Region `
        --parameter-overrides `
            GeminiApiKeyParameter="/allsensesai/gemini/api-key" `
            GeminiModel="gemini-1.5-pro"
    
    Write-Host "  OK Stack deployed" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Stack deployment failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Step 5: Get stack outputs
Write-Host ""
Write-Host "[5/8] Retrieving stack outputs..." -ForegroundColor Yellow

$outputs = aws cloudformation describe-stacks `
    --stack-name $StackName `
    --region $Region `
    --query "Stacks[0].Outputs" `
    --output json | ConvertFrom-Json

$cloudFrontUrl = ($outputs | Where-Object { $_.OutputKey -eq "CloudFrontUrl" }).OutputValue
$lambdaFunctionUrl = ($outputs | Where-Object { $_.OutputKey -eq "LambdaFunctionUrl" }).OutputValue
$s3Bucket = ($outputs | Where-Object { $_.OutputKey -eq "S3BucketName" }).OutputValue
$distributionId = ($outputs | Where-Object { $_.OutputKey -eq "DistributionId" }).OutputValue
$lambdaArn = ($outputs | Where-Object { $_.OutputKey -eq "LambdaFunctionArn" }).OutputValue

Write-Host "  CloudFront URL: $cloudFrontUrl" -ForegroundColor Cyan
Write-Host "  Lambda URL: $lambdaFunctionUrl" -ForegroundColor Cyan
Write-Host "  S3 Bucket: $s3Bucket" -ForegroundColor Cyan
Write-Host "  Distribution ID: $distributionId" -ForegroundColor Cyan

# Step 6: Update Lambda function code
Write-Host ""
Write-Host "[6/8] Updating Lambda function code..." -ForegroundColor Yellow

try {
    aws lambda update-function-code `
        --function-name allsensesai-gemini-analysis `
        --zip-file "fileb://$zipFile" `
        --region $Region | Out-Null
    
    Write-Host "  OK Lambda code updated" -ForegroundColor Green
    
    # Wait for update to complete
    Write-Host "  Waiting for Lambda update..." -ForegroundColor Cyan
    Start-Sleep -Seconds 5
} catch {
    Write-Host "  ERROR: Lambda update failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Step 7: Update UI with Lambda Function URL
Write-Host ""
Write-Host "[7/8] Deploying UI to S3..." -ForegroundColor Yellow

# Read index.html and replace placeholder
$htmlContent = Get-Content "deployment/ui/index.html" -Raw
$htmlContent = $htmlContent -replace '\{\{LAMBDA_FUNCTION_URL\}\}', $lambdaFunctionUrl

# Write to temp file
$tempHtml = "deployment/ui/index-deployed.html"
$htmlContent | Out-File -FilePath $tempHtml -Encoding UTF8

# Upload to S3
try {
    aws s3 cp $tempHtml "s3://$s3Bucket/index.html" `
        --content-type "text/html" `
        --region $Region
    
    Write-Host "  OK UI uploaded to S3" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: S3 upload failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Clean up temp file
Remove-Item $tempHtml

# Step 8: Invalidate CloudFront cache
Write-Host ""
Write-Host "[8/8] Invalidating CloudFront cache..." -ForegroundColor Yellow

try {
    $invalidationId = aws cloudfront create-invalidation `
        --distribution-id $distributionId `
        --paths "/*" `
        --query "Invalidation.Id" `
        --output text `
        --region $Region
    
    Write-Host "  OK Cache invalidation created: $invalidationId" -ForegroundColor Green
    Write-Host "  Cache will be cleared in 1-2 minutes" -ForegroundColor Cyan
} catch {
    Write-Host "  WARNING: Cache invalidation failed (not critical)" -ForegroundColor Yellow
}

# Deployment complete
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Jury Demo URL (HTTPS, GPS-enabled):" -ForegroundColor Cyan
Write-Host "  $cloudFrontUrl" -ForegroundColor White
Write-Host ""
Write-Host "Lambda Function URL:" -ForegroundColor Cyan
Write-Host "  $lambdaFunctionUrl" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Wait 1-2 minutes for CloudFront cache invalidation" -ForegroundColor White
Write-Host "  2. Open the CloudFront URL in your browser" -ForegroundColor White
Write-Host "  3. Check Runtime Health panel shows 'LIVE' status" -ForegroundColor White
Write-Host "  4. Test emergency analysis with sample transcript" -ForegroundColor White
Write-Host ""
Write-Host "Validation:" -ForegroundColor Yellow
Write-Host "  Run: .\deployment\validate-gemini-runtime.ps1" -ForegroundColor White
Write-Host ""

# Save deployment info
$deploymentInfo = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    stackName = $StackName
    region = $Region
    cloudFrontUrl = $cloudFrontUrl
    lambdaFunctionUrl = $lambdaFunctionUrl
    s3Bucket = $s3Bucket
    distributionId = $distributionId
    lambdaArn = $lambdaArn
}

$deploymentInfo | ConvertTo-Json | Out-File "deployment/deployment-info.json" -Encoding UTF8
Write-Host "Deployment info saved to: deployment/deployment-info.json" -ForegroundColor Cyan
