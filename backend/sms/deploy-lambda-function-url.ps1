# Deploy SMS Lambda with Function URL
# Production SMS Restoration - Backend Deployment

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SMS Lambda Function URL Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$STACK_NAME = "allsenses-sms-production"
$TEMPLATE_FILE = "Gemini3_AllSensesAI/backend/sms/template-function-url.yaml"
$LAMBDA_CODE = "Gemini3_AllSensesAI/backend/sms/lambda_function_url_handler.py"
$REGION = "us-east-1"

Write-Host "[1] Validating files..." -ForegroundColor Yellow

if (-not (Test-Path $TEMPLATE_FILE)) {
    Write-Host "ERROR: Template file not found: $TEMPLATE_FILE" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $LAMBDA_CODE)) {
    Write-Host "ERROR: Lambda code not found: $LAMBDA_CODE" -ForegroundColor Red
    exit 1
}

Write-Host "  Template: $TEMPLATE_FILE" -ForegroundColor Green
Write-Host "  Lambda Code: $LAMBDA_CODE" -ForegroundColor Green
Write-Host ""

Write-Host "[2] Packaging Lambda code..." -ForegroundColor Yellow

# Create deployment package
$PACKAGE_DIR = "Gemini3_AllSensesAI/backend/sms/package"
$PACKAGE_ZIP = "Gemini3_AllSensesAI/backend/sms/lambda-function-url.zip"

if (Test-Path $PACKAGE_DIR) {
    Remove-Item -Recurse -Force $PACKAGE_DIR
}
New-Item -ItemType Directory -Path $PACKAGE_DIR | Out-Null

# Copy Lambda code
Copy-Item $LAMBDA_CODE "$PACKAGE_DIR/lambda_function.py"

# Create ZIP
if (Test-Path $PACKAGE_ZIP) {
    Remove-Item -Force $PACKAGE_ZIP
}

Compress-Archive -Path "$PACKAGE_DIR/*" -DestinationPath $PACKAGE_ZIP

Write-Host "  Package created: $PACKAGE_ZIP" -ForegroundColor Green
Write-Host "  Size: $((Get-Item $PACKAGE_ZIP).Length) bytes" -ForegroundColor Green
Write-Host ""

Write-Host "[3] Deploying CloudFormation stack..." -ForegroundColor Yellow

# Deploy stack
aws cloudformation deploy `
    --template-file $TEMPLATE_FILE `
    --stack-name $STACK_NAME `
    --capabilities CAPABILITY_IAM `
    --region $REGION `
    --parameter-overrides `
        LambdaCodeBucket="" `
        LambdaCodeKey=""

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: CloudFormation deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "  Stack deployed successfully" -ForegroundColor Green
Write-Host ""

Write-Host "[4] Updating Lambda code..." -ForegroundColor Yellow

# Get Lambda function name from stack
$FUNCTION_NAME = aws cloudformation describe-stacks `
    --stack-name $STACK_NAME `
    --region $REGION `
    --query "Stacks[0].Outputs[?OutputKey=='LambdaFunctionName'].OutputValue" `
    --output text

Write-Host "  Function Name: $FUNCTION_NAME" -ForegroundColor Green

# Update Lambda code
aws lambda update-function-code `
    --function-name $FUNCTION_NAME `
    --zip-file "fileb://$PACKAGE_ZIP" `
    --region $REGION | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Lambda code update failed" -ForegroundColor Red
    exit 1
}

Write-Host "  Lambda code updated" -ForegroundColor Green
Write-Host ""

Write-Host "[5] Getting Function URL..." -ForegroundColor Yellow

# Get Function URL from stack outputs
$FUNCTION_URL = aws cloudformation describe-stacks `
    --stack-name $STACK_NAME `
    --region $REGION `
    --query "Stacks[0].Outputs[?OutputKey=='FunctionUrl'].OutputValue" `
    --output text

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Lambda Function URL:" -ForegroundColor Cyan
Write-Host "  $FUNCTION_URL" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Copy the Function URL above" -ForegroundColor White
Write-Host "  2. Replace SMS_FUNCTION_URL in frontend HTML" -ForegroundColor White
Write-Host "  3. Deploy frontend to CloudFront" -ForegroundColor White
Write-Host "  4. Test with Colombia +57 number" -ForegroundColor White
Write-Host ""

# Save URL to file for easy access
$FUNCTION_URL | Out-File -FilePath "Gemini3_AllSensesAI/backend/sms/FUNCTION_URL.txt" -Encoding utf8
Write-Host "Function URL saved to: Gemini3_AllSensesAI/backend/sms/FUNCTION_URL.txt" -ForegroundColor Green
Write-Host ""
