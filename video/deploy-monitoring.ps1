#!/usr/bin/env pwsh
# Deploy Video Evidence Monitoring and Alerting Infrastructure
# GEMINI3-GUARDIAN-SMS-VIDEO-20260131-v1

param(
    [string]$AlertEmail = "alerts@allsenses.example.com",
    [int]$VideoCaptureFailureThreshold = 50,
    [int]$VideoUploadFailureThreshold = 30,
    [string]$StackName = "AllSenses-VideoEvidence-Monitoring",
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Video Evidence Monitoring Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Validate email format
if ($AlertEmail -notmatch '^[^@]+@[^@]+\.[^@]+$') {
    Write-Host "ERROR: Invalid email address format: $AlertEmail" -ForegroundColor Red
    Write-Host "Please provide a valid email address for alarm notifications" -ForegroundColor Yellow
    exit 1
}

Write-Host "[1/5] Validating CloudFormation template..." -ForegroundColor Yellow
$templatePath = "infrastructure/video-evidence-monitoring.yaml"

if (-not (Test-Path $templatePath)) {
    Write-Host "ERROR: Template not found: $templatePath" -ForegroundColor Red
    exit 1
}

try {
    aws cloudformation validate-template `
        --template-body file://$templatePath `
        --region $Region `
        --no-cli-pager
    Write-Host "✓ Template validation passed" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Template validation failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/5] Checking if stack exists..." -ForegroundColor Yellow

$stackExists = $false
try {
    $stack = aws cloudformation describe-stacks `
        --stack-name $StackName `
        --region $Region `
        --no-cli-pager 2>$null
    if ($LASTEXITCODE -eq 0) {
        $stackExists = $true
        Write-Host "✓ Stack exists, will update" -ForegroundColor Green
    }
} catch {
    Write-Host "✓ Stack does not exist, will create" -ForegroundColor Green
}

Write-Host ""
Write-Host "[3/5] Deploying monitoring stack..." -ForegroundColor Yellow
Write-Host "  Stack Name: $StackName" -ForegroundColor Cyan
Write-Host "  Region: $Region" -ForegroundColor Cyan
Write-Host "  Alert Email: $AlertEmail" -ForegroundColor Cyan
Write-Host "  Video Capture Failure Threshold: $VideoCaptureFailureThreshold%" -ForegroundColor Cyan
Write-Host "  Video Upload Failure Threshold: $VideoUploadFailureThreshold%" -ForegroundColor Cyan
Write-Host ""

try {
    if ($stackExists) {
        aws cloudformation update-stack `
            --stack-name $StackName `
            --template-body file://$templatePath `
            --parameters `
                ParameterKey=AlertEmail,ParameterValue=$AlertEmail `
                ParameterKey=VideoCaptureFailureThreshold,ParameterValue=$VideoCaptureFailureThreshold `
                ParameterKey=VideoUploadFailureThreshold,ParameterValue=$VideoUploadFailureThreshold `
            --capabilities CAPABILITY_NAMED_IAM `
            --region $Region `
            --no-cli-pager
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: Stack update failed" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "✓ Stack update initiated" -ForegroundColor Green
        Write-Host "Waiting for stack update to complete..." -ForegroundColor Yellow
        
        aws cloudformation wait stack-update-complete `
            --stack-name $StackName `
            --region $Region
    } else {
        aws cloudformation create-stack `
            --stack-name $StackName `
            --template-body file://$templatePath `
            --parameters `
                ParameterKey=AlertEmail,ParameterValue=$AlertEmail `
                ParameterKey=VideoCaptureFailureThreshold,ParameterValue=$VideoCaptureFailureThreshold `
                ParameterKey=VideoUploadFailureThreshold,ParameterValue=$VideoUploadFailureThreshold `
            --capabilities CAPABILITY_NAMED_IAM `
            --region $Region `
            --no-cli-pager
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: Stack creation failed" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "✓ Stack creation initiated" -ForegroundColor Green
        Write-Host "Waiting for stack creation to complete..." -ForegroundColor Yellow
        
        aws cloudformation wait stack-create-complete `
            --stack-name $StackName `
            --region $Region
    }
    
    Write-Host "✓ Stack deployment completed successfully" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Stack deployment failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[4/5] Retrieving stack outputs..." -ForegroundColor Yellow

try {
    $outputs = aws cloudformation describe-stacks `
        --stack-name $StackName `
        --region $Region `
        --query 'Stacks[0].Outputs' `
        --output json `
        --no-cli-pager | ConvertFrom-Json
    
    Write-Host "✓ Stack outputs retrieved" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Deployment Outputs" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    foreach ($output in $outputs) {
        Write-Host "$($output.OutputKey): $($output.OutputValue)" -ForegroundColor White
    }
} catch {
    Write-Host "WARNING: Could not retrieve stack outputs" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[5/5] Verifying SNS topic subscriptions..." -ForegroundColor Yellow

try {
    $alarmTopicArn = ($outputs | Where-Object { $_.OutputKey -eq "AlarmTopicArn" }).OutputValue
    $criticalTopicArn = ($outputs | Where-Object { $_.OutputKey -eq "CriticalAlarmTopicArn" }).OutputValue
    
    if ($alarmTopicArn) {
        Write-Host "  Alarm Topic: $alarmTopicArn" -ForegroundColor Cyan
        $subscriptions = aws sns list-subscriptions-by-topic `
            --topic-arn $alarmTopicArn `
            --region $Region `
            --query 'Subscriptions[*].[Endpoint,SubscriptionArn]' `
            --output text `
            --no-cli-pager
        
        if ($subscriptions) {
            Write-Host "  ✓ Subscriptions configured" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ No subscriptions found" -ForegroundColor Yellow
        }
    }
    
    if ($criticalTopicArn) {
        Write-Host "  Critical Topic: $criticalTopicArn" -ForegroundColor Cyan
        $subscriptions = aws sns list-subscriptions-by-topic `
            --topic-arn $criticalTopicArn `
            --region $Region `
            --query 'Subscriptions[*].[Endpoint,SubscriptionArn]' `
            --output text `
            --no-cli-pager
        
        if ($subscriptions) {
            Write-Host "  ✓ Subscriptions configured" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ No subscriptions found" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "WARNING: Could not verify SNS subscriptions" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT: Check your email ($AlertEmail) to confirm SNS subscriptions" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Confirm SNS subscription emails" -ForegroundColor White
Write-Host "2. View CloudWatch Dashboard: https://console.aws.amazon.com/cloudwatch/home?region=$Region#dashboards:name=AllSenses-VideoEvidence-Monitoring" -ForegroundColor White
Write-Host "3. Test metrics publishing using: ./test-monitoring.ps1" -ForegroundColor White
Write-Host "4. Review alarm configurations in CloudWatch console" -ForegroundColor White
Write-Host ""
