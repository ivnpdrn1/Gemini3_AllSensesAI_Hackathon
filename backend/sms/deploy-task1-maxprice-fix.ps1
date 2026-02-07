# Colombia SMS Task 1 Deployment Script
# Deploys Lambda function with MaxPrice, SMSType, and SenderID attributes

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Colombia SMS Task 1 - MaxPrice Fix" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$LambdaFunctionName = "allsenses-sms-production"
$LambdaFile = "lambda_function_url_handler_v4.py"
$ZipFile = "lambda-task1-maxprice-fix.zip"

Write-Host "[1/5] Verifying Lambda function file..." -ForegroundColor Yellow
if (-not (Test-Path $LambdaFile)) {
    Write-Host "ERROR: Lambda function file not found: $LambdaFile" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Lambda function file found" -ForegroundColor Green
Write-Host ""

Write-Host "[2/5] Creating deployment package..." -ForegroundColor Yellow
if (Test-Path $ZipFile) {
    Remove-Item $ZipFile -Force
}

# Create zip file
Compress-Archive -Path $LambdaFile -DestinationPath $ZipFile -Force
Write-Host "✓ Deployment package created: $ZipFile" -ForegroundColor Green
Write-Host ""

Write-Host "[3/5] Deploying to AWS Lambda..." -ForegroundColor Yellow
try {
    $updateResult = aws lambda update-function-code `
        --function-name $LambdaFunctionName `
        --zip-file "fileb://$ZipFile" `
        --output json 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Lambda deployment failed" -ForegroundColor Red
        Write-Host $updateResult -ForegroundColor Red
        exit 1
    }
    
    $result = $updateResult | ConvertFrom-Json
    Write-Host "✓ Lambda function updated successfully" -ForegroundColor Green
    Write-Host "  Function ARN: $($result.FunctionArn)" -ForegroundColor Gray
    Write-Host "  Last Modified: $($result.LastModified)" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "ERROR: Failed to deploy Lambda function" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "[4/5] Waiting for Lambda function to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
Write-Host "✓ Lambda function ready" -ForegroundColor Green
Write-Host ""

Write-Host "[5/5] Getting Lambda Function URL..." -ForegroundColor Yellow
try {
    $urlConfig = aws lambda get-function-url-config `
        --function-name $LambdaFunctionName `
        --output json 2>&1 | ConvertFrom-Json
    
    $functionUrl = $urlConfig.FunctionUrl
    Write-Host "✓ Lambda Function URL: $functionUrl" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "WARNING: Could not retrieve Function URL" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Run test script: .\test-task1-maxprice-fix.ps1" -ForegroundColor White
Write-Host "2. Verify SMS delivery to Colombia number" -ForegroundColor White
Write-Host ""
