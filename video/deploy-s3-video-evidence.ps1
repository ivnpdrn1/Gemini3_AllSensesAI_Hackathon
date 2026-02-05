# Deploy S3 Video Evidence Infrastructure
# Task 15: Configure S3 bucket and lifecycle policies
# Build: GEMINI3-GUARDIAN-SMS-VIDEO-20260131-v1

param(
    [string]$Region = "us-east-1",
    [int]$RetentionDays = 7,
    [string]$StackName = "allsenses-video-evidence"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "S3 Video Evidence Infrastructure Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verify AWS CLI is installed
Write-Host "[1/6] Verifying AWS CLI..." -ForegroundColor Yellow
try {
    $awsVersion = aws --version 2>&1
    Write-Host "  ✅ AWS CLI found: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "  ❌ AWS CLI not found. Please install AWS CLI first." -ForegroundColor Red
    exit 1
}

# Verify CloudFormation template exists
Write-Host "[2/6] Verifying CloudFormation template..." -ForegroundColor Yellow
$templatePath = "infrastructure/video-evidence-storage.yaml"
if (-not (Test-Path $templatePath)) {
    Write-Host "  ❌ Template not found: $templatePath" -ForegroundColor Red
    exit 1
}
Write-Host "  ✅ Template found: $templatePath" -ForegroundColor Green

# Validate CloudFormation template
Write-Host "[3/6] Validating CloudFormation template..." -ForegroundColor Yellow
try {
    $validation = aws cloudformation validate-template `
        --template-body file://$templatePath `
        --region $Region 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Template validation passed" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Template validation failed: $validation" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ❌ Template validation error: $_" -ForegroundColor Red
    exit 1
}

# Deploy CloudFormation stack
Write-Host "[4/6] Deploying CloudFormation stack..." -ForegroundColor Yellow
Write-Host "  Stack Name: $StackName" -ForegroundColor Cyan
Write-Host "  Region: $Region" -ForegroundColor Cyan
Write-Host "  Retention Days: $RetentionDays" -ForegroundColor Cyan
Write-Host ""

try {
    $deployOutput = aws cloudformation deploy `
        --template-file $templatePath `
        --stack-name $StackName `
        --capabilities CAPABILITY_NAMED_IAM `
        --parameter-overrides RetentionDays=$RetentionDays `
        --region $Region 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Stack deployment successful" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Stack deployment output: $deployOutput" -ForegroundColor Yellow
        
        # Check if stack already exists and is up to date
        if ($deployOutput -match "No changes to deploy") {
            Write-Host "  ✅ Stack already up to date" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Stack deployment failed" -ForegroundColor Red
            exit 1
        }
    }
} catch {
    Write-Host "  ❌ Stack deployment error: $_" -ForegroundColor Red
    exit 1
}

# Get stack outputs
Write-Host "[5/6] Retrieving stack outputs..." -ForegroundColor Yellow
try {
    $outputs = aws cloudformation describe-stacks `
        --stack-name $StackName `
        --region $Region `
        --query 'Stacks[0].Outputs' `
        --output json 2>&1 | ConvertFrom-Json
    
    Write-Host "  ✅ Stack outputs retrieved" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Stack Outputs:" -ForegroundColor Cyan
    Write-Host "  ============================================" -ForegroundColor Cyan
    
    foreach ($output in $outputs) {
        Write-Host "  $($output.OutputKey): $($output.OutputValue)" -ForegroundColor White
    }
    
    # Extract key values
    $bucket = ($outputs | Where-Object { $_.OutputKey -eq 'VideoEvidenceBucket' }).OutputValue
    $lambdaUrl = ($outputs | Where-Object { $_.OutputKey -eq 'VideoStorageURL' }).OutputValue
    $accessTable = ($outputs | Where-Object { $_.OutputKey -eq 'AccessEventsTable' }).OutputValue
    $logGroup = ($outputs | Where-Object { $_.OutputKey -eq 'AccessLogGroup' }).OutputValue
    
} catch {
    Write-Host "  ❌ Failed to retrieve stack outputs: $_" -ForegroundColor Red
    exit 1
}

# Verify S3 bucket configuration
Write-Host ""
Write-Host "[6/6] Verifying S3 bucket configuration..." -ForegroundColor Yellow

# Check encryption
try {
    $encryption = aws s3api get-bucket-encryption `
        --bucket $bucket `
        --region $Region `
        --output json 2>&1 | ConvertFrom-Json
    
    $sseAlgorithm = $encryption.ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm
    
    if ($sseAlgorithm -eq "AES256") {
        Write-Host "  ✅ Encryption: $sseAlgorithm" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Encryption: $sseAlgorithm (expected AES256)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ❌ Failed to verify encryption: $_" -ForegroundColor Red
}

# Check public access block
try {
    $publicAccess = aws s3api get-public-access-block `
        --bucket $bucket `
        --region $Region `
        --output json 2>&1 | ConvertFrom-Json
    
    $config = $publicAccess.PublicAccessBlockConfiguration
    
    if ($config.BlockPublicAcls -and $config.BlockPublicPolicy -and 
        $config.IgnorePublicAcls -and $config.RestrictPublicBuckets) {
        Write-Host "  ✅ Public Access: Fully blocked" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Public Access: Partially blocked" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ❌ Failed to verify public access block: $_" -ForegroundColor Red
}

# Check lifecycle policy
try {
    $lifecycle = aws s3api get-bucket-lifecycle-configuration `
        --bucket $bucket `
        --region $Region `
        --output json 2>&1 | ConvertFrom-Json
    
    $rule = $lifecycle.Rules[0]
    
    if ($rule.Status -eq "Enabled" -and $rule.Expiration.Days -eq $RetentionDays) {
        Write-Host "  ✅ Lifecycle Policy: $($rule.Id) - $($rule.Expiration.Days) days" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Lifecycle Policy: Status=$($rule.Status), Days=$($rule.Expiration.Days)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ❌ Failed to verify lifecycle policy: $_" -ForegroundColor Red
}

# Check CORS configuration
try {
    $cors = aws s3api get-bucket-cors `
        --bucket $bucket `
        --region $Region `
        --output json 2>&1 | ConvertFrom-Json
    
    $corsRule = $cors.CORSRules[0]
    
    if ($corsRule.AllowedMethods -contains "GET" -and $corsRule.AllowedMethods -contains "HEAD") {
        Write-Host "  ✅ CORS: Configured for signed URLs (GET, HEAD)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  CORS: Methods=$($corsRule.AllowedMethods -join ', ')" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ❌ Failed to verify CORS configuration: $_" -ForegroundColor Red
}

# Test Lambda Function URL
Write-Host ""
Write-Host "Testing Lambda Function URL..." -ForegroundColor Yellow
try {
    $testPayload = @{
        action = "generate_signed_url"
        s3Key = "test/dummy.mp4"
        expirationMinutes = 20
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri $lambdaUrl -Method POST -Body $testPayload -ContentType "application/json" -ErrorAction Stop
    
    if ($response.status -eq "error" -and $response.error -match "NoSuchKey|does not exist") {
        Write-Host "  ✅ Lambda Function URL accessible (expected error for non-existent key)" -ForegroundColor Green
    } elseif ($response.status -eq "success") {
        Write-Host "  ✅ Lambda Function URL accessible and functional" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Lambda response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ❌ Lambda Function URL test failed: $_" -ForegroundColor Red
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ S3 Bucket: $bucket" -ForegroundColor Green
Write-Host "✅ Lambda URL: $lambdaUrl" -ForegroundColor Green
Write-Host "✅ Access Table: $accessTable" -ForegroundColor Green
Write-Host "✅ Log Group: $logGroup" -ForegroundColor Green
Write-Host "✅ Retention: $RetentionDays days" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Update frontend VideoStorageService with Lambda URL" -ForegroundColor White
Write-Host "2. Update frontend SignedURLGenerator with Lambda URL" -ForegroundColor White
Write-Host "3. Test video upload integration" -ForegroundColor White
Write-Host "4. Test signed URL generation" -ForegroundColor White
Write-Host "5. Verify 7-day expiration (manual check after 7 days)" -ForegroundColor White
Write-Host ""
Write-Host "Configuration saved to: deployment-config.json" -ForegroundColor Cyan

# Save configuration to file
$config = @{
    stackName = $StackName
    region = $Region
    retentionDays = $RetentionDays
    bucket = $bucket
    lambdaUrl = $lambdaUrl
    accessTable = $accessTable
    logGroup = $logGroup
    deploymentTimestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    buildId = "GEMINI3-GUARDIAN-SMS-VIDEO-20260131-v1"
}

$config | ConvertTo-Json -Depth 10 | Out-File "Gemini3_AllSensesAI/video/deployment-config.json" -Encoding UTF8

Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host ""
