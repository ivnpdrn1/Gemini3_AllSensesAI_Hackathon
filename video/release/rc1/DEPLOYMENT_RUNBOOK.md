# Deployment Runbook - Video SMS Evidence Capture RC1

**Purpose:** Step-by-step guide for deploying video SMS evidence capture to production  
**Date:** 2026-02-02  
**Build:** GEMINI3-GUARDIAN-SMS-VIDEO-20260201-v1  
**Release Candidate:** RC1  

---

## Prerequisites

Before starting deployment, ensure you have:

- [ ] AWS CLI installed and configured
- [ ] AWS credentials with permissions for S3, CloudFront, CloudFormation, SNS, CloudWatch
- [ ] Access to S3 bucket and CloudFront distribution
- [ ] Email address for SNS alert notifications
- [ ] Git repository access (for tagging)
- [ ] Browser for manual testing (Chrome/Edge recommended)

---

## Deployment Parameters

You will need these values for the deployment:

| Parameter | Value | Example |
|-----------|-------|---------|
| **BucketName** | Your S3 bucket name | `allsenses-production-frontend` |
| **DistributionId** | Your CloudFront distribution ID | `E1234567890ABC` |
| **AlertEmail** | Email for CloudWatch alarms | `ops@example.com` |
| **Region** | AWS region | `us-east-1` |
| **CloudFront URL** | Production URL | `https://dfc8ght8abwqc.cloudfront.net` |

---

## Deployment Phases

The deployment consists of 9 phases (A-I) with human checkpoints between each phase.

### Phase A: Pre-Flight Checks

**Purpose:** Validate environment before deployment

**Command:**
```powershell
cd Gemini3_AllSensesAI/video/release/rc1
.\preflight-checks.ps1 -BucketName YOUR-BUCKET-NAME -DistributionId YOUR-DISTRIBUTION-ID -Region us-east-1
```

**Expected Output:**
- ✅ AWS CLI installed
- ✅ AWS identity verified
- ✅ S3 bucket accessible
- ✅ CloudFront distribution accessible
- ✅ All required files present
- ✅ Git status clean (or warnings only)
- ✅ Baseline production file unchanged (hash verified)
- ✅ Video variant file ready

**Checkpoint:** Review all checks passed before proceeding

---

### Phase B: Deploy S3 Storage Stack

**Purpose:** Create S3 bucket for video evidence storage

**Command:**
```powershell
cd Gemini3_AllSensesAI/video
.\deploy-s3-video-evidence.ps1 -Region us-east-1
```

**What This Does:**
- Creates S3 bucket: `allsenses-video-evidence-us-east-1`
- Enables AES-256 encryption
- Blocks all public access
- Configures CORS for signed URL access
- Sets lifecycle policy (7-day auto-delete)
- Creates Lambda function for video uploads

**Expected Output:**
```
Stack Status: CREATE_COMPLETE
Bucket Name: allsenses-video-evidence-us-east-1
Lambda URL: https://[random].lambda-url.us-east-1.on.aws/
```

**Verification:**
```powershell
# Verify bucket exists
aws s3 ls s3://allsenses-video-evidence-us-east-1 --region us-east-1

# Verify stack deployed
aws cloudformation describe-stacks --stack-name allsenses-video-evidence-storage --region us-east-1
```

**Checkpoint:** Confirm S3 stack deployed successfully

---

### Phase C: Deploy Monitoring Stack

**Purpose:** Create CloudWatch metrics, alarms, and SNS notifications

**Command:**
```powershell
cd Gemini3_AllSensesAI/video
.\deploy-monitoring.ps1 -AlertEmail YOUR-EMAIL@example.com -Region us-east-1
```

**What This Does:**
- Creates CloudWatch dashboard: `VideoEvidenceMetrics`
- Creates metrics: VideoCapture.Success/Failure, VideoUpload.Success/Failure, SMS.WithVideo/WithoutVideo
- Creates alarms: Video capture failure rate, video upload failure rate, SMS delivery failures
- Creates SNS topic for alarm notifications
- Sends email subscription confirmation

**Expected Output:**
```
Stack Status: CREATE_COMPLETE
SNS Topic: arn:aws:sns:us-east-1:123456789012:VideoEvidenceAlerts
Dashboard: VideoEvidenceMetrics
```

**CRITICAL:** Check your email and click the SNS subscription confirmation link

**Verification:**
```powershell
# Verify stack deployed
aws cloudformation describe-stacks --stack-name allsenses-video-evidence-monitoring --region us-east-1

# Verify SNS subscription
aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:us-east-1:123456789012:VideoEvidenceAlerts --region us-east-1
```

**Checkpoint:** Confirm SNS email subscription before proceeding

---

### Phase D: Frontend Integration

**Purpose:** Wire deployed Lambda URLs to frontend configuration

**What This Does:**
- Retrieves Lambda URL from CloudFormation outputs
- Updates `deployment-config.json` with Lambda URL
- Prepares frontend for video upload integration

**Manual Steps:**
1. Get Lambda URL from CloudFormation:
   ```powershell
   aws cloudformation describe-stacks --stack-name allsenses-video-evidence-storage --region us-east-1 --query "Stacks[0].Outputs[?OutputKey=='VideoUploadLambdaUrl'].OutputValue" --output text
   ```

2. Update `Gemini3_AllSensesAI/deployment-config.json`:
   ```json
   {
     "videoUploadLambdaUrl": "https://[random].lambda-url.us-east-1.on.aws/"
   }
   ```

3. Verify configuration:
   ```powershell
   cat Gemini3_AllSensesAI/deployment-config.json
   ```

**Checkpoint:** Verify Lambda URL wired correctly

---

### Phase E: Local E2E Test

**Purpose:** Test video capture, upload, and SMS delivery locally before production deployment

**Manual Testing Required:**

1. Open local file in browser:
   ```
   file:///C:/Users/[YOUR-USER]/OneDrive/Documents/Kiro/Gemini3_AllSensesAI/gemini3-guardian-production-sms-video.html
   ```

2. Follow `SMOKE_TEST.md` checklist:
   - [ ] Page loads without errors
   - [ ] No console errors on page load
   - [ ] Step 1 button works
   - [ ] Steps 2-3 work normally
   - [ ] Video panel appears in Step 4 only
   - [ ] Video capture triggers after emergency confirmation
   - [ ] Video upload succeeds (check network tab)
   - [ ] SMS sends with video URL
   - [ ] Video failures are non-blocking (test camera denied)

3. Collect proof:
   - Screenshot of console logs
   - Screenshot of network tab (video upload request)
   - Screenshot of SMS received with video URL

**Checkpoint:** Confirm local E2E tests passed

---

### Phase F: Production Deployment

**Purpose:** Deploy video variant to CloudFront

**Command:**
```powershell
cd Gemini3_AllSensesAI/video/release/rc1
.\deploy-production-sms-video.ps1 -BucketName YOUR-BUCKET-NAME -DistributionId YOUR-DISTRIBUTION-ID -SkipInvalidation
```

**What This Does:**
- Uploads `gemini3-guardian-production-sms-video.html` to `/video/index.html`
- Uploads 4 JS modules to `/video/*.js`
- Sets correct Content-Type headers
- Creates CloudFront invalidation (if not skipped)
- Prints test URLs

**Expected Output:**
```
Uploading HTML file...
Uploading JS modules...
  VideoCaptureModule.js -> 200 OK
  VideoStorageService.js -> 200 OK
  SignedURLGenerator.js -> 200 OK
  IntegrationOrchestrator.js -> 200 OK

Test URLs:
  Video Variant: https://dfc8ght8abwqc.cloudfront.net/video/index.html
  Baseline Production: https://dfc8ght8abwqc.cloudfront.net/
```

**Verification:**
```powershell
# Verify files uploaded
aws s3 ls s3://YOUR-BUCKET-NAME/video/ --recursive

# Verify Content-Type
aws s3api head-object --bucket YOUR-BUCKET-NAME --key video/VideoCaptureModule.js
```

**Checkpoint:** Confirm deployment succeeded

---

### Phase G: Production Verification

**Purpose:** Verify production deployment works end-to-end

**Manual Testing Required:**

1. Open production URL in browser:
   ```
   https://dfc8ght8abwqc.cloudfront.net/video/index.html
   ```

2. Follow `POST_DEPLOY_VERIFICATION.md` checklist:
   - [ ] All 4 JS modules load with 200 status
   - [ ] All JS modules have Content-Type: `application/javascript`
   - [ ] No SyntaxError in console
   - [ ] No ReferenceError for `completeStep1`
   - [ ] Step 1 button works normally
   - [ ] Video capture works in Step 4
   - [ ] Video upload succeeds
   - [ ] SMS sends with video URL
   - [ ] Baseline production unchanged: `https://dfc8ght8abwqc.cloudfront.net/`

3. Collect proof:
   - Screenshot of network tab (all JS 200)
   - Screenshot of console logs (no errors)
   - Screenshot of SMS received with video URL
   - Screenshot of baseline production (unchanged)

**Troubleshooting:**

If JS files return 403:
1. Check S3 bucket for files
2. Check Content-Type headers
3. Create manual CloudFront invalidation
4. Wait 1-5 minutes and hard refresh browser

**Checkpoint:** Confirm production verification passed

---

### Phase H: Git Branch + Release Tag

**Purpose:** Create git artifacts for release tracking

**Commands:**
```powershell
# Create release branch
git checkout -b release/video-sms-evidence-rc1-$(Get-Date -Format "yyyyMMdd-HHmmss")

# Create release tag
git tag -a v2026.01.31-video-v1 -m "Video SMS Evidence Capture RC1 - Production Deployment"

# Push to remote (optional)
git push origin release/video-sms-evidence-rc1-[timestamp]
git push origin v2026.01.31-video-v1
```

**Checkpoint:** Confirm git artifacts created

---

### Phase I: Final Deployment Report

**Purpose:** Generate deployment report for documentation

**What This Does:**
- Creates `VIDEO_SMS_EVIDENCE_DEPLOYMENT_REPORT.md`
- Documents all deployment phases
- Records deployment URLs
- Records infrastructure details
- Provides rollback instructions
- Links to monitoring dashboard

**Expected Output:**
```
Deployment report saved: VIDEO_SMS_EVIDENCE_DEPLOYMENT_REPORT.md
```

**Review Report:**
```powershell
cat VIDEO_SMS_EVIDENCE_DEPLOYMENT_REPORT.md
```

---

## Master Orchestrator (Automated)

Instead of running each phase manually, you can use the master orchestrator script:

```powershell
cd Gemini3_AllSensesAI/video/release/rc1

.\MASTER_DEPLOYMENT_ORCHESTRATOR.ps1 `
  -BucketName YOUR-BUCKET-NAME `
  -DistributionId YOUR-DISTRIBUTION-ID `
  -AlertEmail YOUR-EMAIL@example.com `
  -Region us-east-1 `
  -SkipInvalidation
```

**What This Does:**
- Runs all 9 phases sequentially
- Pauses at each checkpoint for human review
- Generates final deployment report
- Provides rollback instructions if needed

**Human Checkpoints:**
- After Phase A: Review pre-flight results
- After Phase B: Verify S3 stack deployed
- After Phase C: Confirm SNS email subscription
- After Phase D: Verify Lambda URL wired
- After Phase E: Confirm local E2E tests passed
- After Phase F: Verify deployment succeeded
- After Phase G: Confirm production verification passed
- After Phase H: Confirm git artifacts created

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
- Removes `/video/` path from S3
- Creates CloudFront invalidation for `/video/*`
- Restores baseline production state
- Verifies baseline production still functional

**Rollback Time:** < 2 minutes

---

## Post-Deployment Monitoring

After successful deployment, monitor for 24-48 hours:

1. **CloudWatch Dashboard:**
   ```
   https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=VideoEvidenceMetrics
   ```

2. **Key Metrics to Watch:**
   - VideoCapture.Success (should increase during emergencies)
   - VideoCapture.Failure (should be < 50%)
   - VideoUpload.Success (should match capture success)
   - VideoUpload.Failure (should be < 30%)
   - SMS.WithVideo (should increase when video succeeds)
   - SMS.WithoutVideo (should increase when video fails)

3. **Alarm Notifications:**
   - Check email for alarm notifications
   - Investigate any CRITICAL alarms immediately
   - Review WARNING alarms within 1 hour

4. **User Feedback:**
   - Monitor support channels for user reports
   - Collect feedback on video capture experience
   - Document any issues or edge cases

---

## Success Criteria

Deployment is considered successful when:

- [x] All 9 phases completed without errors
- [x] Pre-flight checks passed
- [x] S3 and monitoring stacks deployed
- [x] Local E2E tests passed
- [x] Production deployment succeeded
- [x] Production verification passed
- [x] All JS modules load with 200 status
- [x] No console errors on page load
- [x] Video capture works in Step 4
- [x] Video failures are non-blocking
- [x] SMS delivery works with and without video
- [x] Baseline production unchanged
- [x] No regressions detected
- [x] Git artifacts created
- [x] Deployment report generated
- [x] Monitoring dashboard active
- [x] SNS alerts configured

---

## Contact Information

**Release Manager:** [FILL: Your Name]  
**Email:** [FILL: Your Email]  
**Slack:** [FILL: Your Slack Handle]  
**Emergency Contact:** [FILL: Emergency Phone]  

---

## Appendix: Quick Reference Commands

### Check Deployment Status
```powershell
# Check S3 files
aws s3 ls s3://YOUR-BUCKET-NAME/video/ --recursive

# Check CloudFormation stacks
aws cloudformation describe-stacks --stack-name allsenses-video-evidence-storage --region us-east-1
aws cloudformation describe-stacks --stack-name allsenses-video-evidence-monitoring --region us-east-1

# Check CloudFront distribution
aws cloudfront get-distribution --id YOUR-DISTRIBUTION-ID
```

### Manual CloudFront Invalidation
```powershell
aws cloudfront create-invalidation --distribution-id YOUR-DISTRIBUTION-ID --paths "/video/*"
```

### View CloudWatch Metrics
```powershell
aws cloudwatch get-metric-statistics --namespace VideoEvidence --metric-name VideoCapture.Success --start-time 2026-02-02T00:00:00Z --end-time 2026-02-02T23:59:59Z --period 3600 --statistics Sum --region us-east-1
```

### Test URLs
```
Baseline Production: https://dfc8ght8abwqc.cloudfront.net/
Video Variant: https://dfc8ght8abwqc.cloudfront.net/video/index.html
```

---

**End of Deployment Runbook**
