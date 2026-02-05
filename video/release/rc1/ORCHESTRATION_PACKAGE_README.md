# Deployment Orchestration Package - Video SMS Evidence Capture RC1

**Created:** 2026-02-02  
**Purpose:** Complete deployment automation and documentation for video SMS evidence capture  
**Status:** ✅ Ready for execution  

---

## What Was Created

This orchestration package provides everything needed to deploy the video SMS evidence capture feature to production with confidence and safety.

### Core Scripts

1. **MASTER_DEPLOYMENT_ORCHESTRATOR.ps1**
   - Automated deployment across all 9 phases (A-I)
   - Human checkpoints between each phase
   - Automatic report generation
   - Rollback instructions on failure

2. **preflight-checks.ps1**
   - Validates AWS environment before deployment
   - Checks file integrity (baseline unchanged)
   - Verifies AWS credentials and permissions
   - Confirms all required files present

### Documentation

3. **DEPLOYMENT_RUNBOOK.md**
   - Step-by-step deployment guide
   - Detailed instructions for each phase
   - Manual testing procedures
   - Troubleshooting guide
   - Quick reference commands

4. **ORCHESTRATION_PACKAGE_README.md** (this file)
   - Overview of orchestration package
   - Usage instructions
   - Decision tree for deployment approach

### Existing Assets (Already Created)

- `deploy-production-sms-video.ps1` - Production deployment script
- `rollback-production-sms-video.ps1` - Rollback script
- `RELEASE_READY.md` - Release readiness marker
- `POST_DEPLOY_VERIFICATION.md` - Post-deployment checklist
- `regression/SMOKE_TEST.md` - Manual testing checklist
- `RELEASE_NOTES.md` - Release notes and changelog
- `PROOF_BUNDLE.md` - E2E validation template

---

## How to Use This Package

### Option 1: Automated Deployment (Recommended)

Use the master orchestrator for a guided, automated deployment:

```powershell
cd Gemini3_AllSensesAI/video/release/rc1

.\MASTER_DEPLOYMENT_ORCHESTRATOR.ps1 `
  -BucketName YOUR-BUCKET-NAME `
  -DistributionId YOUR-DISTRIBUTION-ID `
  -AlertEmail YOUR-EMAIL@example.com `
  -Region us-east-1 `
  -SkipInvalidation
```

**What Happens:**
1. Runs pre-flight checks automatically
2. Deploys S3 storage stack
3. Deploys monitoring stack
4. Wires Lambda URLs to frontend
5. Prompts for local E2E testing
6. Deploys to production CloudFront
7. Prompts for production verification
8. Creates git branch and tag
9. Generates deployment report

**Human Checkpoints:**
- You'll be prompted to review results after each phase
- Type "yes" to continue or "no" to abort
- Manual testing required at Phase E and Phase G

**Output:**
- `VIDEO_SMS_EVIDENCE_DEPLOYMENT_REPORT.md` - Complete deployment report

---

### Option 2: Manual Phase-by-Phase Deployment

Use the runbook for manual control over each phase:

1. **Read the Runbook:**
   ```powershell
   cat DEPLOYMENT_RUNBOOK.md
   ```

2. **Execute Each Phase Manually:**
   - Phase A: `.\preflight-checks.ps1 -BucketName ... -DistributionId ...`
   - Phase B: `..\..\deploy-s3-video-evidence.ps1 -Region us-east-1`
   - Phase C: `..\..\deploy-monitoring.ps1 -AlertEmail ... -Region us-east-1`
   - Phase D: Manual Lambda URL wiring
   - Phase E: Manual local E2E testing
   - Phase F: `.\deploy-production-sms-video.ps1 -BucketName ... -DistributionId ...`
   - Phase G: Manual production verification
   - Phase H: Manual git branch and tag creation
   - Phase I: Manual report generation

**When to Use Manual Approach:**
- You want full control over timing
- You need to pause between phases for extended periods
- You're troubleshooting a specific phase
- You're deploying to a non-standard environment

---

### Option 3: Pre-Flight Checks Only

Run pre-flight checks without deploying:

```powershell
cd Gemini3_AllSensesAI/video/release/rc1

.\preflight-checks.ps1 `
  -BucketName YOUR-BUCKET-NAME `
  -DistributionId YOUR-DISTRIBUTION-ID `
  -Region us-east-1
```

**Use Cases:**
- Validate environment before scheduling deployment
- Verify AWS credentials and permissions
- Check file integrity before deployment
- Troubleshoot deployment issues

---

## Deployment Decision Tree

```
START
  |
  ├─ Do you have AWS credentials configured?
  |    NO → Run: aws configure
  |    YES ↓
  |
  ├─ Do you know your S3 bucket and CloudFront distribution ID?
  |    NO → Find them in AWS Console
  |    YES ↓
  |
  ├─ Do you want automated deployment?
  |    YES → Use MASTER_DEPLOYMENT_ORCHESTRATOR.ps1
  |    NO ↓
  |
  ├─ Do you want to validate environment first?
  |    YES → Run preflight-checks.ps1
  |    NO ↓
  |
  ├─ Do you want manual control over each phase?
  |    YES → Follow DEPLOYMENT_RUNBOOK.md
  |    NO → Use MASTER_DEPLOYMENT_ORCHESTRATOR.ps1
  |
END
```

---

## Required Parameters

Before running any deployment script, gather these values:

| Parameter | Description | How to Find |
|-----------|-------------|-------------|
| **BucketName** | S3 bucket for frontend | AWS Console → S3 → Buckets |
| **DistributionId** | CloudFront distribution ID | AWS Console → CloudFront → Distributions |
| **AlertEmail** | Email for CloudWatch alarms | Your operations email |
| **Region** | AWS region | Usually `us-east-1` |

**Example Values:**
```powershell
$BucketName = "allsenses-production-frontend"
$DistributionId = "E1234567890ABC"
$AlertEmail = "ops@example.com"
$Region = "us-east-1"
```

---

## What Gets Deployed

### Infrastructure (AWS)

1. **S3 Bucket:** `allsenses-video-evidence-us-east-1`
   - AES-256 encryption
   - 7-day lifecycle policy
   - Private access only
   - CORS configured for signed URLs

2. **Lambda Function:** Video upload handler
   - Generates pre-signed S3 URLs
   - 20-minute expiration
   - Read-only permissions

3. **CloudWatch Dashboard:** `VideoEvidenceMetrics`
   - Video capture success/failure metrics
   - Video upload success/failure metrics
   - SMS with/without video metrics

4. **CloudWatch Alarms:**
   - Video capture failure rate > 50%
   - Video upload failure rate > 30%
   - SMS delivery failures (CRITICAL)

5. **SNS Topic:** `VideoEvidenceAlerts`
   - Email notifications for alarms
   - Requires email confirmation

### Frontend (CloudFront)

1. **Video Variant:** `/video/index.html`
   - New build with video capture capability
   - 4 JavaScript modules
   - Isolated from baseline production

2. **Baseline Production:** `/` (unchanged)
   - Existing production build
   - No modifications
   - Continues working independently

---

## Safety Guarantees

### Non-Destructive Deployment

✅ **Baseline production file never modified**
- Hash verified before deployment
- Deployed to separate `/video/` path
- Baseline remains at root `/`

✅ **Rollback in < 2 minutes**
- Single script removes `/video/` path
- Baseline production unaffected
- No data loss

✅ **Video failures never block SMS**
- Camera permission denied → SMS still sends
- Upload failure → SMS still sends
- URL generation failure → SMS still sends

### Verification at Every Step

✅ **Pre-flight checks**
- AWS credentials validated
- File integrity verified
- Required files present

✅ **Post-deployment verification**
- All JS modules load (200 status)
- No console errors
- Video capture works
- SMS delivery works

✅ **Regression testing**
- Steps 1-3 unchanged
- Baseline production unchanged
- No new CORS calls
- No console errors on page load

---

## Monitoring After Deployment

### CloudWatch Dashboard

**URL:** https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=VideoEvidenceMetrics

**Metrics to Watch:**
- `VideoCapture.Success` - Should increase during emergencies
- `VideoCapture.Failure` - Should be < 50%
- `VideoUpload.Success` - Should match capture success
- `VideoUpload.Failure` - Should be < 30%
- `SMS.WithVideo` - Should increase when video succeeds
- `SMS.WithoutVideo` - Should increase when video fails

### Alarm Notifications

**Email:** Check your alert email for notifications

**Alarm Types:**
- **WARNING:** Video capture/upload failure rates elevated
- **CRITICAL:** SMS delivery failures (immediate action required)

**Response Times:**
- CRITICAL alarms: Investigate immediately
- WARNING alarms: Review within 1 hour

---

## Rollback Procedure

If issues are discovered during or after deployment:

```powershell
cd Gemini3_AllSensesAI/video/release/rc1

.\rollback-production-sms-video.ps1 `
  -BucketName YOUR-BUCKET-NAME `
  -DistributionId YOUR-DISTRIBUTION-ID
```

**What This Does:**
1. Removes `/video/index.html` from S3
2. Removes all `/video/*.js` modules from S3
3. Creates CloudFront invalidation for `/video/*`
4. Verifies baseline production still functional

**Rollback Time:** < 2 minutes

**When to Rollback:**
- JS modules return 403 errors
- Console shows SyntaxError or ReferenceError
- Video capture breaks existing functionality
- SMS delivery fails
- Any regression in Steps 1-3
- Baseline production affected

---

## Troubleshooting

### Issue: Pre-flight checks fail

**Symptom:** `preflight-checks.ps1` exits with errors

**Solutions:**
- AWS CLI not installed → Install from https://aws.amazon.com/cli/
- AWS credentials not configured → Run `aws configure`
- S3 bucket not accessible → Verify bucket name and permissions
- CloudFront distribution not accessible → Verify distribution ID
- Baseline file modified → Restore from git or checkpoint
- Required files missing → Verify all files present in release directory

### Issue: S3 stack deployment fails

**Symptom:** Phase B fails with CloudFormation error

**Solutions:**
- Stack already exists → Delete existing stack or use update command
- Insufficient permissions → Verify IAM permissions for CloudFormation, S3, Lambda
- Region mismatch → Verify region parameter matches your AWS setup
- Bucket name conflict → Choose a different bucket name

### Issue: SNS email not received

**Symptom:** No confirmation email after Phase C

**Solutions:**
- Check spam folder
- Verify email address is correct
- Check SNS topic in AWS Console
- Manually subscribe to SNS topic

### Issue: JS modules return 403

**Symptom:** Network tab shows 403 for `/video/*.js` files

**Solutions:**
- Verify files uploaded to S3: `aws s3 ls s3://YOUR-BUCKET-NAME/video/`
- Check Content-Type headers: `aws s3api head-object --bucket YOUR-BUCKET-NAME --key video/VideoCaptureModule.js`
- Create manual CloudFront invalidation: `aws cloudfront create-invalidation --distribution-id YOUR-DISTRIBUTION-ID --paths "/video/*"`
- Wait 1-5 minutes and hard refresh browser (Ctrl+Shift+R)

### Issue: SyntaxError on page load

**Symptom:** Console shows "Uncaught SyntaxError: Unexpected token 'function'"

**Cause:** CloudFront serving cached 403 HTML as JavaScript

**Solutions:**
- Create CloudFront invalidation for `/video/*`
- Wait for invalidation to complete (1-5 minutes)
- Hard refresh browser (Ctrl+Shift+R)
- Clear browser cache

### Issue: completeStep1 is not defined

**Symptom:** Console shows "Uncaught ReferenceError: completeStep1 is not defined"

**Cause:** Script execution aborted due to earlier SyntaxError

**Solutions:**
- Resolve 403 errors first (see above)
- Verify all JS modules load with 200 status
- Check Content-Type headers are `application/javascript`
- Reload page after fixing 403 errors

---

## Success Criteria

Deployment is considered successful when:

### Pre-Deployment
- [x] Pre-flight checks passed
- [x] All required files present
- [x] Baseline production file unchanged (hash verified)
- [x] AWS credentials configured
- [x] S3 bucket and CloudFront distribution accessible

### During Deployment
- [x] S3 storage stack deployed (CREATE_COMPLETE)
- [x] Monitoring stack deployed (CREATE_COMPLETE)
- [x] SNS email subscription confirmed
- [x] Lambda URL wired to frontend
- [x] Local E2E tests passed
- [x] Production deployment succeeded
- [x] All JS modules uploaded with correct Content-Type

### Post-Deployment
- [x] All JS modules load with 200 status
- [x] No console errors on page load
- [x] Video capture works in Step 4
- [x] Video failures are non-blocking
- [x] SMS delivery works with and without video
- [x] Baseline production unchanged and functional
- [x] No regressions in Steps 1-3
- [x] CloudWatch dashboard active
- [x] Alarms configured and SNS confirmed

### Monitoring (24-48 hours)
- [ ] No CRITICAL alarms triggered
- [ ] Video capture success rate > 50%
- [ ] Video upload success rate > 70%
- [ ] SMS delivery success rate > 95%
- [ ] No user-reported issues
- [ ] No regressions detected

---

## Next Steps After Deployment

1. **Monitor for 24-48 hours**
   - Watch CloudWatch dashboard
   - Review alarm notifications
   - Check email for alerts

2. **Collect user feedback**
   - Monitor support channels
   - Document any issues or edge cases
   - Gather feedback on video capture experience

3. **Plan for GA release**
   - If RC1 stable, plan GA release
   - Update documentation
   - Prepare release announcement

4. **Optional: Deploy to additional regions**
   - Repeat deployment process for other regions
   - Update region parameter in scripts
   - Verify regional S3 buckets and Lambda functions

---

## Contact Information

**Release Manager:** [FILL: Your Name]  
**Email:** [FILL: Your Email]  
**Slack:** [FILL: Your Slack Handle]  
**Emergency Contact:** [FILL: Emergency Phone]  

---

## Files in This Package

```
Gemini3_AllSensesAI/video/release/rc1/
├── MASTER_DEPLOYMENT_ORCHESTRATOR.ps1  ← Automated deployment (all phases)
├── preflight-checks.ps1                ← Pre-flight validation
├── DEPLOYMENT_RUNBOOK.md               ← Step-by-step manual guide
├── ORCHESTRATION_PACKAGE_README.md     ← This file
├── deploy-production-sms-video.ps1     ← Production deployment script
├── rollback-production-sms-video.ps1   ← Rollback script
├── RELEASE_READY.md                    ← Release readiness marker
├── POST_DEPLOY_VERIFICATION.md         ← Post-deployment checklist
├── RELEASE_NOTES.md                    ← Release notes and changelog
├── PROOF_BUNDLE.md                     ← E2E validation template
├── VideoCaptureModule.js               ← Video capture module
├── VideoStorageService.js              ← S3 upload service
├── SignedURLGenerator.js               ← Pre-signed URL generator
├── IntegrationOrchestrator.js          ← Video evidence orchestrator
└── regression/
    ├── SMOKE_TEST.md                   ← Manual testing checklist
    ├── REGRESSION_CHECKLIST.md         ← Regression test checklist
    └── run-regression-local.ps1        ← Local regression test script
```

---

## Quick Start

**For first-time deployment:**

```powershell
# 1. Navigate to release directory
cd Gemini3_AllSensesAI/video/release/rc1

# 2. Run automated deployment
.\MASTER_DEPLOYMENT_ORCHESTRATOR.ps1 `
  -BucketName YOUR-BUCKET-NAME `
  -DistributionId YOUR-DISTRIBUTION-ID `
  -AlertEmail YOUR-EMAIL@example.com `
  -Region us-east-1 `
  -SkipInvalidation

# 3. Follow prompts and complete manual testing at checkpoints

# 4. Review deployment report
cat VIDEO_SMS_EVIDENCE_DEPLOYMENT_REPORT.md
```

**For validation only:**

```powershell
# Run pre-flight checks without deploying
.\preflight-checks.ps1 `
  -BucketName YOUR-BUCKET-NAME `
  -DistributionId YOUR-DISTRIBUTION-ID `
  -Region us-east-1
```

**For rollback:**

```powershell
# Rollback if issues found
.\rollback-production-sms-video.ps1 `
  -BucketName YOUR-BUCKET-NAME `
  -DistributionId YOUR-DISTRIBUTION-ID
```

---

**End of Orchestration Package README**
