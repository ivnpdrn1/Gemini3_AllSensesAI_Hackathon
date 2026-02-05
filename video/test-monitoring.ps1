#!/usr/bin/env pwsh
# Test Video Evidence Monitoring Infrastructure
# GEMINI3-GUARDIAN-SMS-VIDEO-20260131-v1

param(
    [string]$StackName = "AllSenses-VideoEvidence-Monitoring",
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Video Evidence Monitoring Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get stack outputs
Write-Host "[1/4] Retrieving stack outputs..." -ForegroundColor Yellow

try {
    $outputs = aws cloudformation describe-stacks `
        --stack-name $StackName `
        --region $Region `
        --query 'Stacks[0].Outputs' `
        --output json `
        --no-cli-pager | ConvertFrom-Json
    
    $logGroupName = ($outputs | Where-Object { $_.OutputKey -eq "MetricsLogGroupName" }).OutputValue
    
    if (-not $logGroupName) {
        Write-Host "ERROR: Could not find MetricsLogGroupName in stack outputs" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ Log Group: $logGroupName" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Could not retrieve stack outputs" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/4] Publishing test metrics..." -ForegroundColor Yellow

# Test log messages that should trigger metrics
$testMessages = @(
    "[VIDEO] capture completed",
    "[VIDEO] permission denied",
    "[VIDEO] upload success",
    "[VIDEO] upload failure",
    "[SMS] sent with video URL",
    "[SMS] sent without video URL"
)

foreach ($message in $testMessages) {
    try {
        aws logs put-log-events `
            --log-group-name $logGroupName `
            --log-stream-name "test-stream-$(Get-Date -Format 'yyyyMMdd-HHmmss')" `
            --log-events "timestamp=$(([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())),message=$message" `
            --region $Region `
            --no-cli-pager 2>$null
        
        Write-Host "  ✓ Published: $message" -ForegroundColor Green
    } catch {
        # Log stream might not exist, try creating it
        try {
            $streamName = "test-stream-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            aws logs create-log-stream `
                --log-group-name $logGroupName `
                --log-stream-name $streamName `
                --region $Region `
                --no-cli-pager 2>$null
            
            aws logs put-log-events `
                --log-group-name $logGroupName `
                --log-stream-name $streamName `
                --log-events "timestamp=$(([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())),message=$message" `
                --region $Region `
                --no-cli-pager 2>$null
            
            Write-Host "  ✓ Published: $message" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠ Failed to publish: $message" -ForegroundColor Yellow
        }
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "[3/4] Waiting for metrics to propagate (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host ""
Write-Host "[4/4] Verifying metrics..." -ForegroundColor Yellow

$metricsToCheck = @(
    "VideoCaptureSuccess",
    "VideoCaptureFailure",
    "VideoUploadSuccess",
    "VideoUploadFailure",
    "SMSWithVideo",
    "SMSWithoutVideo"
)

$endTime = [DateTimeOffset]::UtcNow
$startTime = $endTime.AddMinutes(-10)

foreach ($metricName in $metricsToCheck) {
    try {
        $result = aws cloudwatch get-metric-statistics `
            --namespace "AllSenses/VideoEvidence" `
            --metric-name $metricName `
            --start-time $startTime.ToString("yyyy-MM-ddTHH:mm:ssZ") `
            --end-time $endTime.ToString("yyyy-MM-ddTHH:mm:ssZ") `
            --period 300 `
            --statistics Sum `
            --region $Region `
            --output json `
            --no-cli-pager | ConvertFrom-Json
        
        if ($result.Datapoints.Count -gt 0) {
            $sum = ($result.Datapoints | Measure-Object -Property Sum -Sum).Sum
            Write-Host "  ✓ $metricName : $sum events" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ $metricName : No data points (metrics may take time to appear)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ✗ $metricName : Error retrieving metric" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Monitoring Test Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Notes:" -ForegroundColor Cyan
Write-Host "- Metrics may take 5-10 minutes to appear in CloudWatch" -ForegroundColor White
Write-Host "- Check the dashboard: https://console.aws.amazon.com/cloudwatch/home?region=$Region#dashboards:name=AllSenses-VideoEvidence-Monitoring" -ForegroundColor White
Write-Host "- Alarms will trigger based on configured thresholds" -ForegroundColor White
Write-Host ""
