# Pre-Flight Checks - Video SMS Evidence Capture RC1
# Purpose: Validate environment before deployment
# Date: 2026-02-02

param(
    [Parameter(Mandatory=$true)]
    [string]$BucketName,
    
    [Parameter(Mandatory=$true)]
    [string]$DistributionId,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PASS = 0
$FAIL = 0

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PRE-FLIGHT CHECKS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# CHECK 1: AWS CLI Installed
# ============================================================================

Write-Host "[CHECK 1] AWS CLI Installation" -ForegroundColor Yellow
try {
    $awsVersion = aws --version 2>&1
    Write-Host "  AWS CLI: $awsVersion" -ForegroundColor Green
    $PASS++
} catch {
    Write-Host "  ERROR: AWS CLI not installed" -ForegroundColor Red
    Write-Host "  Install: https://aws.amazon.com/cli/" -ForegroundColor Gray
    $FAIL++
}
Write-Host ""

# ============================================================================
# CHECK 2: AWS Identity
# ============================================================================

Write-Host "[CHECK 2] AWS Identity" -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Host "  Account: $($identity.Account)" -ForegroundColor Green
    Write-Host "  User: $($identity.Arn)" -ForegroundColor Green
    $PASS++
} catch {
    Write-Host "  ERROR: AWS credentials not configured" -ForegroundColor Red
    Write-Host "  Run: aws configure" -ForegroundColor Gray
    $FAIL++
}
Write-Host ""

# ============================================================================
# CHECK 3: S3 Bucket Access
# ============================================================================

Write-Host "[CHECK 3] S3 Bucket Access" -ForegroundColor Yellow
try {
    $bucketExists = aws s3 ls "s3://$BucketName" --region $Region 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Bucket exists: s3://$BucketName" -ForegroundColor Green
        $PASS++
    } else {
        Write-Host "  ERROR: Cannot access bucket: s3://$BucketName" -ForegroundColor Red
        Write-Host "  Verify bucket name and permissions" -ForegroundColor Gray
        $FAIL++
    }
} catch {
    Write-Host "  ERROR: S3 access failed" -ForegroundColor Red
    $FAIL++
}
Write-Host ""

# ============================================================================
# CHECK 4: CloudFront Distribution Access
# ============================================================================

Write-Host "[CHECK 4] CloudFront Distribution Access" -ForegroundColor Yellow
try {
    $distribution = aws cloudfront get-distribution --id $DistributionId --output json 2>&1 | ConvertFrom-Json
    if ($distribution.Distribution) {
        Write-Host "  Distribution ID: $DistributionId" -ForegroundColor Green
        Write-Host "  Domain: $($distribution.Distribution.DomainName)" -ForegroundColor Green
        Write-Host "  Status: $($distribution.Distribution.Status)" -ForegroundColor Green
        $PASS++
    } else {
        Write-Host "  ERROR: Cannot access distribution: $DistributionId" -ForegroundColor Red
        $FAIL++
    }
} catch {
    Write-Host "  ERROR: CloudFront access failed" -ForegroundColor Red
    Write-Host "  Verify distribution ID and permissions" -ForegroundColor Gray
    $FAIL++
}
Write-Host ""

# ============================================================================
# CHECK 5: Required Files Exist
# ============================================================================

Write-Host "[CHECK 5] Required Files Exist" -ForegroundColor Yellow

$requiredFiles = @(
    "../../../gemini3-guardian-production-sms-video.html",
    "../../../gemini3-guardian-production-sms.html",
    "VideoCaptureModule.js",
    "VideoStorageService.js",
    "SignedURLGenerator.js",
    "IntegrationOrchestrator.js",
    "deploy-production-sms-video.ps1",
    "rollback-production-sms-video.ps1",
    "../../deploy-s3-video-evidence.ps1",
    "../../deploy-monitoring.ps1",
    "../../../infrastructure/video-evidence-storage.yaml",
    "../../../infrastructure/video-evidence-monitoring.yaml"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $PSScriptRoot $file
    if (Test-Path $fullPath) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (MISSING)" -ForegroundColor Red
        $missingFiles += $file
    }
}

if ($missingFiles.Count -eq 0) {
    Write-Host "  All required files present" -ForegroundColor Green
    $PASS++
} else {
    Write-Host "  ERROR: $($missingFiles.Count) files missing" -ForegroundColor Red
    $FAIL++
}
Write-Host ""

# ============================================================================
# CHECK 6: Git Status
# ============================================================================

Write-Host "[CHECK 6] Git Status" -ForegroundColor Yellow
try {
    $gitStatus = git status --porcelain 2>&1
    if ([string]::IsNullOrWhiteSpace($gitStatus)) {
        Write-Host "  Working directory clean" -ForegroundColor Green
        $PASS++
    } else {
        Write-Host "  WARNING: Uncommitted changes detected" -ForegroundColor Yellow
        Write-Host "  Consider committing before deployment" -ForegroundColor Gray
        $PASS++  # Not a failure, just a warning
    }
    
    $currentBranch = git branch --show-current 2>&1
    Write-Host "  Current branch: $currentBranch" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Git not available or not a git repository" -ForegroundColor Yellow
    $PASS++  # Not a failure
}
Write-Host ""

# ============================================================================
# CHECK 7: Baseline Production File Integrity
# ============================================================================

Write-Host "[CHECK 7] Baseline Production File Integrity" -ForegroundColor Yellow

$baselineFile = Join-Path $PSScriptRoot "../../../gemini3-guardian-production-sms.html"
$canonicalHash = "3EE4EC5F221BEE1B15D4B467A35D59D8C567BF88C380341CD5A5D63E27F98B8D"

if (Test-Path $baselineFile) {
    $currentHash = (Get-FileHash -Path $baselineFile -Algorithm SHA256).Hash
    if ($currentHash -eq $canonicalHash) {
        Write-Host "  Baseline file unchanged (hash verified)" -ForegroundColor Green
        Write-Host "  Hash: $currentHash" -ForegroundColor Gray
        $PASS++
    } else {
        Write-Host "  ERROR: Baseline file has been modified" -ForegroundColor Red
        Write-Host "  Expected: $canonicalHash" -ForegroundColor Gray
        Write-Host "  Current:  $currentHash" -ForegroundColor Gray
        $FAIL++
    }
} else {
    Write-Host "  ERROR: Baseline file not found" -ForegroundColor Red
    $FAIL++
}
Write-Host ""

# ============================================================================
# CHECK 8: Video Variant File Exists
# ============================================================================

Write-Host "[CHECK 8] Video Variant File Exists" -ForegroundColor Yellow

$videoFile = Join-Path $PSScriptRoot "../../../gemini3-guardian-production-sms-video.html"
$expectedHash = "1400ED51E4F5416BF1DD91063648018EB8B9E28EE0693FC1FB577E85A6F8B992"

if (Test-Path $videoFile) {
    $currentHash = (Get-FileHash -Path $videoFile -Algorithm SHA256).Hash
    if ($currentHash -eq $expectedHash) {
        Write-Host "  Video variant file ready (hash verified)" -ForegroundColor Green
        Write-Host "  Hash: $currentHash" -ForegroundColor Gray
        $PASS++
    } else {
        Write-Host "  WARNING: Video variant hash differs from checkpoint" -ForegroundColor Yellow
        Write-Host "  Expected: $expectedHash" -ForegroundColor Gray
        Write-Host "  Current:  $currentHash" -ForegroundColor Gray
        Write-Host "  This may be expected if changes were made after checkpoint" -ForegroundColor Gray
        $PASS++  # Not a failure, just a warning
    }
} else {
    Write-Host "  ERROR: Video variant file not found" -ForegroundColor Red
    $FAIL++
}
Write-Host ""

# ============================================================================
# CHECK 9: CloudFormation Stack Status
# ============================================================================

Write-Host "[CHECK 9] CloudFormation Stack Status" -ForegroundColor Yellow

$stacks = @(
    "allsenses-video-evidence-storage",
    "allsenses-video-evidence-monitoring"
)

foreach ($stackName in $stacks) {
    try {
        $stack = aws cloudformation describe-stacks --stack-name $stackName --region $Region --output json 2>&1 | ConvertFrom-Json
        if ($stack.Stacks) {
            $status = $stack.Stacks[0].StackStatus
            if ($status -eq "CREATE_COMPLETE" -or $status -eq "UPDATE_COMPLETE") {
                Write-Host "  ✓ $stackName : $status" -ForegroundColor Green
            } else {
                Write-Host "  ⚠ $stackName : $status" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ✗ $stackName : NOT DEPLOYED" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  ✗ $stackName : NOT DEPLOYED" -ForegroundColor Gray
    }
}

Write-Host "  Note: Stacks will be deployed during Phase B and C" -ForegroundColor Gray
$PASS++
Write-Host ""

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PRE-FLIGHT SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Checks Passed: $PASS" -ForegroundColor Green
Write-Host "Checks Failed: $FAIL" -ForegroundColor $(if ($FAIL -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($FAIL -eq 0) {
    Write-Host "✅ PRE-FLIGHT CHECKS PASSED" -ForegroundColor Green
    Write-Host "Ready to proceed with deployment" -ForegroundColor Green
    Write-Host ""
    exit 0
} else {
    Write-Host "❌ PRE-FLIGHT CHECKS FAILED" -ForegroundColor Red
    Write-Host "Fix errors above before proceeding" -ForegroundColor Red
    Write-Host ""
    exit 1
}
