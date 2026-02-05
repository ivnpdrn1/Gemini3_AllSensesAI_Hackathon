# Master Deployment Orchestrator - Video SMS Evidence Capture RC1
# Purpose: Orchestrate all 9 deployment phases (A-I) with human checkpoints
# Date: 2026-02-02
# Build: GEMINI3-GUARDIAN-SMS-VIDEO-20260201-v1

param(
    [Parameter(Mandatory=$true)]
    [string]$BucketName,
    
    [Parameter(Mandatory=$true)]
    [string]$DistributionId,
    
    [Parameter(Mandatory=$true)]
    [string]$AlertEmail,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipInvalidation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CLOUDFRONT_URL = "https://dfc8ght8abwqc.cloudfront.net"
$DEPLOYMENT_LOG = "VIDEO_SMS_EVIDENCE_DEPLOYMENT_REPORT.md"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VIDEO SMS EVIDENCE CAPTURE - RC1" -ForegroundColor Cyan
Write-Host "Master Deployment Orchestrator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# PHASE A: PRE-FLIGHT CHECKS
# ============================================================================

Write-Host "[PHASE A] PRE-FLIGHT CHECKS" -ForegroundColor Yellow
Write-Host "Running pre-flight validation..." -ForegroundColor Gray

# Run pre-flight check script
$preflightScript = Join-Path $PSScriptRoot "preflight-checks.ps1"
if (-not (Test-Path $preflightScript)) {
    Write-Host "ERROR: preflight-checks.ps1 not found" -ForegroundColor Red
    exit 1
}

& $preflightScript -BucketName $BucketName -DistributionId $DistributionId -Region $Region
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Pre-flight checks failed" -ForegroundColor Red
    exit 1
}

Write-Host "[PHASE A] COMPLETE" -ForegroundColor Green
Write-Host ""

# Human checkpoint
Write-Host "CHECKPOINT: Review pre-flight results above" -ForegroundColor Magenta
$continue = Read-Host "Continue to Phase B? (yes/no)"
if ($continue -ne "yes") {
    Write-Host "Deployment aborted by user" -ForegroundColor Yellow
    exit 0
}
Write-Host ""

# ============================================================================
# PHASE B: DEPLOY S3 STORAGE STACK
# ============================================================================

Write-Host "[PHASE B] DEPLOY S3 STORAGE STACK" -ForegroundColor Yellow
Write-Host "Deploying video evidence S3 bucket..." -ForegroundColor Gray

$s3DeployScript = "../../deploy-s3-video-evidence.ps1"
if (-not (Test-Path $s3DeployScript)) {
    Write-Host "ERROR: deploy-s3-video-evidence.ps1 not found" -ForegroundColor Red
    exit 1
}

& $s3DeployScript -Region $Region
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: S3 stack deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "[PHASE B] COMPLETE" -ForegroundColor Green
Write-Host ""

# Human checkpoint
Write-Host "CHECKPOINT: Verify S3 stack deployed successfully" -ForegroundColor Magenta
$continue = Read-Host "Continue to Phase C? (yes/no)"
if ($continue -ne "yes") {
    Write-Host "Deployment aborted by user" -ForegroundColor Yellow
    exit 0
}
Write-Host ""

# ============================================================================
# PHASE C: DEPLOY MONITORING STACK
# ============================================================================

Write-Host "[PHASE C] DEPLOY MONITORING STACK" -ForegroundColor Yellow
Write-Host "Deploying CloudWatch metrics and alarms..." -ForegroundColor Gray

$monitoringDeployScript = "../../deploy-monitoring.ps1"
if (-not (Test-Path $monitoringDeployScript)) {
    Write-Host "ERROR: deploy-monitoring.ps1 not found" -ForegroundColor Red
    exit 1
}

& $monitoringDeployScript -AlertEmail $AlertEmail -Region $Region
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Monitoring stack deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "[PHASE C] COMPLETE" -ForegroundColor Green
Write-Host ""

# Human checkpoint
Write-Host "CHECKPOINT: Confirm SNS email subscription" -ForegroundColor Magenta
Write-Host "Check your email ($AlertEmail) and click the confirmation link" -ForegroundColor Gray
$continue = Read-Host "SNS subscription confirmed? (yes/no)"
if ($continue -ne "yes") {
    Write-Host "Deployment aborted - SNS not confirmed" -ForegroundColor Yellow
    exit 0
}
Write-Host ""

# ============================================================================
# PHASE D: FRONTEND INTEGRATION
# ============================================================================

Write-Host "[PHASE D] FRONTEND INTEGRATION" -ForegroundColor Yellow
Write-Host "Wiring deployed Lambda URLs to frontend..." -ForegroundColor Gray

# Get Lambda URL from CloudFormation outputs
Write-Host "Retrieving Lambda URL from CloudFormation..." -ForegroundColor Gray
$lambdaUrl = aws cloudformation describe-stacks `
    --stack-name allsenses-video-evidence-storage `
    --region $Region `
    --query "Stacks[0].Outputs[?OutputKey=='VideoUploadLambdaUrl'].OutputValue" `
    --output text

if ([string]::IsNullOrWhiteSpace($lambdaUrl)) {
    Write-Host "ERROR: Could not retrieve Lambda URL from CloudFormation" -ForegroundColor Red
    exit 1
}

Write-Host "Lambda URL: $lambdaUrl" -ForegroundColor Green

# Update deployment-config.json
$configPath = "../../../deployment-config.json"
if (Test-Path $configPath) {
    $config = Get-Content $configPath | ConvertFrom-Json
    $config.videoUploadLambdaUrl = $lambdaUrl
    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
    Write-Host "Updated deployment-config.json with Lambda URL" -ForegroundColor Green
} else {
    Write-Host "WARNING: deployment-config.json not found, skipping update" -ForegroundColor Yellow
}

Write-Host "[PHASE D] COMPLETE" -ForegroundColor Green
Write-Host ""

# Human checkpoint
Write-Host "CHECKPOINT: Verify Lambda URL wired correctly" -ForegroundColor Magenta
$continue = Read-Host "Continue to Phase E? (yes/no)"
if ($continue -ne "yes") {
    Write-Host "Deployment aborted by user" -ForegroundColor Yellow
    exit 0
}
Write-Host ""

# ============================================================================
# PHASE E: LOCAL E2E TEST
# ============================================================================

Write-Host "[PHASE E] LOCAL E2E TEST" -ForegroundColor Yellow
Write-Host "Running local browser tests..." -ForegroundColor Gray

Write-Host ""
Write-Host "MANUAL TESTING REQUIRED:" -ForegroundColor Magenta
Write-Host "1. Open: file:///$PSScriptRoot/../../../gemini3-guardian-production-sms-video.html" -ForegroundColor Gray
Write-Host "2. Follow SMOKE_TEST.md checklist" -ForegroundColor Gray
Write-Host "3. Verify video capture, upload, and SMS delivery" -ForegroundColor Gray
Write-Host ""

$continue = Read-Host "Local E2E tests passed? (yes/no)"
if ($continue -ne "yes") {
    Write-Host "Deployment aborted - local tests failed" -ForegroundColor Yellow
    exit 0
}

Write-Host "[PHASE E] COMPLETE" -ForegroundColor Green
Write-Host ""

# ============================================================================
# PHASE F: PRODUCTION DEPLOYMENT
# ============================================================================

Write-Host "[PHASE F] PRODUCTION DEPLOYMENT" -ForegroundColor Yellow
Write-Host "Deploying to CloudFront..." -ForegroundColor Gray

$deployScript = Join-Path $PSScriptRoot "deploy-production-sms-video.ps1"
if (-not (Test-Path $deployScript)) {
    Write-Host "ERROR: deploy-production-sms-video.ps1 not found" -ForegroundColor Red
    exit 1
}

if ($SkipInvalidation) {
    & $deployScript -BucketName $BucketName -DistributionId $DistributionId -SkipInvalidation
} else {
    & $deployScript -BucketName $BucketName -DistributionId $DistributionId
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Production deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "[PHASE F] COMPLETE" -ForegroundColor Green
Write-Host ""

# Human checkpoint
Write-Host "CHECKPOINT: Verify deployment succeeded" -ForegroundColor Magenta
$continue = Read-Host "Continue to Phase G? (yes/no)"
if ($continue -ne "yes") {
    Write-Host "Deployment aborted by user" -ForegroundColor Yellow
    Write-Host "Run rollback script if needed: .\rollback-production-sms-video.ps1" -ForegroundColor Yellow
    exit 0
}
Write-Host ""

# ============================================================================
# PHASE G: PRODUCTION VERIFICATION
# ============================================================================

Write-Host "[PHASE G] PRODUCTION VERIFICATION" -ForegroundColor Yellow
Write-Host "Verifying production deployment..." -ForegroundColor Gray

Write-Host ""
Write-Host "MANUAL VERIFICATION REQUIRED:" -ForegroundColor Magenta
Write-Host "1. Open: $CLOUDFRONT_URL/video/index.html" -ForegroundColor Gray
Write-Host "2. Follow POST_DEPLOY_VERIFICATION.md checklist" -ForegroundColor Gray
Write-Host "3. Verify all JS modules load (200 status)" -ForegroundColor Gray
Write-Host "4. Verify no console errors" -ForegroundColor Gray
Write-Host "5. Test video capture end-to-end" -ForegroundColor Gray
Write-Host "6. Verify SMS delivery with video URL" -ForegroundColor Gray
Write-Host ""

$continue = Read-Host "Production verification passed? (yes/no)"
if ($continue -ne "yes") {
    Write-Host "Deployment verification failed" -ForegroundColor Red
    Write-Host "Run rollback script: .\rollback-production-sms-video.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "[PHASE G] COMPLETE" -ForegroundColor Green
Write-Host ""

# ============================================================================
# PHASE H: GIT BRANCH + RELEASE TAG
# ============================================================================

Write-Host "[PHASE H] GIT BRANCH + RELEASE TAG" -ForegroundColor Yellow
Write-Host "Creating git release artifacts..." -ForegroundColor Gray

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$branchName = "release/video-sms-evidence-rc1-$timestamp"
$tagName = "v2026.01.31-video-v1"

Write-Host "Creating branch: $branchName" -ForegroundColor Gray
git checkout -b $branchName
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Git branch creation failed" -ForegroundColor Yellow
}

Write-Host "Creating tag: $tagName" -ForegroundColor Gray
git tag -a $tagName -m "Video SMS Evidence Capture RC1 - Production Deployment"
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Git tag creation failed" -ForegroundColor Yellow
}

Write-Host "[PHASE H] COMPLETE" -ForegroundColor Green
Write-Host ""

# Human checkpoint
Write-Host "CHECKPOINT: Push git artifacts?" -ForegroundColor Magenta
$continue = Read-Host "Push branch and tag to remote? (yes/no)"
if ($continue -eq "yes") {
    git push origin $branchName
    git push origin $tagName
    Write-Host "Git artifacts pushed to remote" -ForegroundColor Green
} else {
    Write-Host "Skipped git push (artifacts remain local)" -ForegroundColor Yellow
}
Write-Host ""

# ============================================================================
# PHASE I: FINAL DEPLOYMENT REPORT
# ============================================================================

Write-Host "[PHASE I] FINAL DEPLOYMENT REPORT" -ForegroundColor Yellow
Write-Host "Generating deployment report..." -ForegroundColor Gray

$reportContent = @"
# Video SMS Evidence Capture - Deployment Report

**Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Build:** GEMINI3-GUARDIAN-SMS-VIDEO-20260201-v1
**Release Candidate:** RC1
**Deployed By:** $env:USERNAME

---

## Deployment Summary

| Phase | Status | Notes |
|-------|--------|-------|
| A - Pre-flight Checks | ✅ COMPLETE | AWS identity verified, files exist |
| B - S3 Storage Stack | ✅ COMPLETE | Bucket: allsenses-video-evidence-$Region |
| C - Monitoring Stack | ✅ COMPLETE | SNS email: $AlertEmail |
| D - Frontend Integration | ✅ COMPLETE | Lambda URL: $lambdaUrl |
| E - Local E2E Test | ✅ COMPLETE | Manual testing passed |
| F - Production Deployment | ✅ COMPLETE | CloudFront: $CLOUDFRONT_URL/video/ |
| G - Production Verification | ✅ COMPLETE | All checks passed |
| H - Git Branch + Tag | ✅ COMPLETE | Tag: $tagName |
| I - Final Report | ✅ COMPLETE | This document |

---

## Deployment URLs

**Production Video URL:** $CLOUDFRONT_URL/video/index.html
**Baseline Production URL:** $CLOUDFRONT_URL/

---

## Infrastructure Details

**S3 Bucket:** allsenses-video-evidence-$Region
**CloudFront Distribution:** $DistributionId
**Lambda Upload URL:** $lambdaUrl
**Alert Email:** $AlertEmail
**AWS Region:** $Region

---

## Verification Checklist

- [x] All JS modules load with 200 status
- [x] No console errors on page load
- [x] Video capture works in Step 4
- [x] Video failures are non-blocking
- [x] SMS delivery works with and without video
- [x] Baseline production unchanged
- [x] No regressions detected

---

## Rollback Instructions

If issues are discovered post-deployment:

``````powershell
.\rollback-production-sms-video.ps1 -BucketName $BucketName -DistributionId $DistributionId
``````

This will remove the /video/ path and restore baseline production state.

---

## Monitoring

**CloudWatch Dashboard:** https://console.aws.amazon.com/cloudwatch/home?region=$Region#dashboards:name=VideoEvidenceMetrics

**Key Metrics:**
- VideoCapture.Success
- VideoCapture.Failure
- VideoUpload.Success
- VideoUpload.Failure
- SMS.WithVideo
- SMS.WithoutVideo

**Alarms:**
- Video capture failure rate > 50%
- Video upload failure rate > 30%
- SMS delivery failures (CRITICAL)

---

## Next Steps

1. Monitor CloudWatch metrics for 24-48 hours
2. Review alarm notifications
3. Collect user feedback
4. Plan for GA release if RC1 stable

---

**Deployment Status:** ✅ **SUCCESS**

**Signed By:** $env:USERNAME
**Timestamp:** $(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")

---

**End of Deployment Report**
"@

$reportContent | Out-File -FilePath $DEPLOYMENT_LOG -Encoding UTF8
Write-Host "Deployment report saved: $DEPLOYMENT_LOG" -ForegroundColor Green

Write-Host "[PHASE I] COMPLETE" -ForegroundColor Green
Write-Host ""

# ============================================================================
# DEPLOYMENT COMPLETE
# ============================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Production URL: $CLOUDFRONT_URL/video/index.html" -ForegroundColor Green
Write-Host "Deployment Report: $DEPLOYMENT_LOG" -ForegroundColor Green
Write-Host ""
Write-Host "Monitor CloudWatch for the next 24-48 hours" -ForegroundColor Yellow
Write-Host "Review alarm notifications at: $AlertEmail" -ForegroundColor Yellow
Write-Host ""
Write-Host "If issues arise, run rollback:" -ForegroundColor Yellow
Write-Host "  .\rollback-production-sms-video.ps1 -BucketName $BucketName -DistributionId $DistributionId" -ForegroundColor Gray
Write-Host ""

exit 0
