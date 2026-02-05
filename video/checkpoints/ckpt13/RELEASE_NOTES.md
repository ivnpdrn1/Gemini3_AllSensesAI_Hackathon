# Release Candidate 1 (RC1) - Video SMS Evidence Capture

**Build ID**: `GEMINI3-GUARDIAN-SMS-VIDEO-20260201-v1`  
**Release Date**: 2026-02-01  
**Status**: Release Candidate (Manual Testing Required)

---

## Overview

This release candidate adds **video evidence capture** to the AllSensesAI Guardian emergency detection system. Video capture is triggered automatically during Step 4 emergency confirmation and includes the video URL in SMS alerts sent to emergency contacts.

---

## New Features

### 1. Video Evidence Capture (Step 4)
- **Automatic Activation**: Video capture triggers after Gemini Vision confirms emergency
- **Frame Capture**: Captures 3-5 video frames OR maximum 3 seconds of video
- **Camera Permission**: Requests user permission only when needed (not on page load)
- **Non-Blocking Failures**: Video capture failures never block SMS delivery

### 2. SMS Integration
- **Video URL in Payload**: Adds optional `videoEvidenceUrl` field to SMS payload
- **Video Link in Message**: Appends video evidence link to SMS message text
- **Backward Compatible**: SMS works with or without video capture

### 3. Video Panel UI (Step 4 Only)
- **Status Badge**: Shows video capture status (standby, capturing, complete, error)
- **Thumbnails**: Displays captured video frames after successful capture
- **Warning Messages**: Shows non-blocking warnings on capture failure
- **Step 4 Isolation**: Video panel only appears in Step 4 (not in Steps 1-3)

---

## Non-Destructive Guarantees

### ✅ Steps 1-3 Unchanged
- **Step 1 Button**: `<button onclick="completeStep1()">✅ Complete Step 1</button>` preserved
- **Step 2 Location**: All location handlers unchanged
- **Step 3 Voice**: All voice detection handlers unchanged
- **No Modifications**: Zero changes to existing Step 1-3 code

### ✅ SMS Flow Preserved
- **Existing Logic**: SMS composition, validation, and delivery unchanged
- **Backward Compatible**: SMS sends successfully with or without video
- **No Breaking Changes**: Existing SMS payload fields unchanged

### ✅ Proof Logging Added
- **Video Operations**: `[VIDEO]` prefix for all video-related logs
- **SMS Integration**: `[SMS_VIDEO]` prefix for video URL injection logs
- **Audit Trail**: Complete proof of video capture and SMS integration

---

## Known Limitations

### Backend Compatibility
- **Current Status**: Backend Lambda **tolerates** `videoEvidenceUrl` field but does NOT extract or process it
- **Behavior**: Video URL is included in SMS message text by frontend
- **Future Enhancement**: Backend can be updated to extract and log video URL

### Video Capture Requirements
- **Camera Access**: Requires user permission (browser prompt)
- **Browser Support**: Requires modern browser with MediaRecorder API
- **Network Access**: Requires S3 upload capability (not implemented in RC1)

### Manual Testing Required
- **E2E Validation**: Requires manual browser testing to verify complete flow
- **SMS Delivery**: Requires real phone number for SMS testing
- **Camera Permission**: Requires user interaction (cannot be automated)

---

## Deployment Strategy

### Parallel Path Deployment
**CRITICAL**: Deploy video variant to a **separate S3 key** to preserve baseline production build.

**Recommended S3 Keys**:
- **Baseline Production**: `index.html` (unchanged)
- **Video Variant**: `video/index.html` OR `gemini3-guardian-production-sms-video.html`

**CloudFront Routing**:
- **Production URL**: `https://example.cloudfront.net/` → `index.html` (baseline)
- **Video URL**: `https://example.cloudfront.net/video/` → `video/index.html` (video variant)

### Cache Control
Use aggressive cache-busting for safe iteration:
```
Cache-Control: max-age=0, no-cache, no-store, must-revalidate
```

### Invalidation
Invalidate only the video path (not `/*`):
```
/video/index.html
/gemini3-guardian-production-sms-video.html
```

---

## Rollback Procedure

### Instant Rollback
1. **Delete Video S3 Key**: Remove video variant from S3
2. **Invalidate CloudFront**: Clear video path from CDN cache
3. **Verify Baseline**: Confirm production build still accessible

### Rollback Script
Use `rollback-production-sms-video.ps1` to automate rollback:
```powershell
.\rollback-production-sms-video.ps1 -BucketName "your-bucket" -DistributionId "E1234567890ABC"
```

### Rollback Verification
- Confirm video URL returns 404 or redirects to baseline
- Confirm baseline production URL still works
- Confirm no console errors on page load

---

## Testing Checklist

### Pre-Deployment
- [ ] Run regression tests (verify Steps 1-3 unchanged)
- [ ] Verify build ID: `GEMINI3-GUARDIAN-SMS-VIDEO-20260201-v1`
- [ ] Verify no console errors on page load
- [ ] Verify no network calls on page load

### Post-Deployment
- [ ] Test SMS without video (baseline test)
- [ ] Test SMS with video (new functionality)
- [ ] Test video capture failure (non-blocking)
- [ ] Verify video panel only in Step 4
- [ ] Verify console logs show proof messages

### Rollback Test
- [ ] Execute rollback script
- [ ] Verify video URL inaccessible
- [ ] Verify baseline production URL works
- [ ] Verify no console errors

---

## Files Included in RC1

### Core Files
- `gemini3-guardian-production-sms-video.html` - Video variant HTML (4746 lines)

### Video Modules
- `VideoCaptureModule.js` - Client-side video capture
- `VideoStorageService.js` - S3 upload integration
- `SignedURLGenerator.js` - Time-limited URL generation
- `IntegrationOrchestrator.js` - Video evidence orchestrator

### Tests
- `tests/property-tests.js` - Property-based tests for video capture

### Checkpoints
- `checkpoints/ckpt1/` through `checkpoints/ckpt11/` - Development checkpoints
- Each checkpoint includes backup files and detailed reports

---

## Deployment Scripts

### Deploy Script
`deploy-production-sms-video.ps1` - Deploy video variant to S3 + CloudFront

**Usage**:
```powershell
.\deploy-production-sms-video.ps1 `
    -BucketName "your-s3-bucket" `
    -DistributionId "E1234567890ABC" `
    -VideoPath "video/index.html"
```

### Rollback Script
`rollback-production-sms-video.ps1` - Rollback to baseline production

**Usage**:
```powershell
# Safe mode (with confirmation prompt)
.\rollback-production-sms-video.ps1 `
    -BucketName "your-s3-bucket" `
    -DistributionId "E1234567890ABC"

# Force mode (no confirmation prompt)
.\rollback-production-sms-video.ps1 `
    -BucketName "your-s3-bucket" `
    -DistributionId "E1234567890ABC" `
    -Force
```

**Force Mode**: Use `-Force` parameter to skip confirmation prompt for instant rollback in emergency situations.

---

## Regression Test Harness

### Overview
RC1 includes a comprehensive regression test harness to verify baseline production file remains unchanged and no regressions are introduced.

### Regression Scripts

#### 1. Local Regression Test
`regression/run-regression-local.ps1` - Verify baseline file unchanged

**Purpose**:
- Compute SHA256 hash of baseline production file
- Compute SHA256 hash of video variant file
- Verify baseline hash matches known checkpoint 1 hash
- Write hashes to `regression/hashes.txt`
- Fail with non-zero exit code if baseline hash mismatch

**Usage**:
```powershell
.\regression\run-regression-local.ps1
```

**Known Baseline Hash** (from checkpoint 1):
```
015EC574E9E65D66FA5B0A120347EC9183411674DB465F20E0E48ED7108704A7
```

#### 2. Deployment Regression Test
`regression/run-regression-deploy.ps1` - Print test URLs and proof collection commands

**Purpose**:
- Print exact deployed URLs to test (baseline + video path)
- Print step-by-step proof collection commands
- Append timestamped test run header to PROOF_BUNDLE.md

**Usage**:
```powershell
.\regression\run-regression-deploy.ps1 `
    -CloudFrontDomain "example.cloudfront.net" `
    -BaselinePath "index.html" `
    -VideoPath "video/index.html"
```

#### 3. Regression Checklist
`regression/REGRESSION_CHECKLIST.md` - Comprehensive regression test checklist

**Includes**:
- Step 1 button preservation (emoji/text/onclick unchanged)
- No network calls on page load
- No camera prompt before Step 4 click
- SMS baseline without video
- Video capture + SMS with appended link
- Failure cases (deny camera, upload fail) non-blocking
- CORS: no OPTIONS preflight until user action

**Total Tests**: 12 (7 critical, 5 additional)

### Regression Test Workflow

1. **Run Local Regression Test**:
   ```powershell
   .\regression\run-regression-local.ps1
   ```
   - Verifies baseline file unchanged
   - Computes hashes for both files
   - Writes hashes to `regression/hashes.txt`

2. **Deploy to Staging/Production**:
   ```powershell
   .\deploy-production-sms-video.ps1 -BucketName "..." -DistributionId "..."
   ```

3. **Run Deployment Regression Test**:
   ```powershell
   .\regression\run-regression-deploy.ps1 -CloudFrontDomain "..."
   ```
   - Prints test URLs
   - Prints proof collection commands
   - Appends test run header to PROOF_BUNDLE.md

4. **Execute Manual Tests**:
   - Follow `regression/REGRESSION_CHECKLIST.md`
   - Collect proof (console logs, network requests, screenshots)
   - Fill PROOF_BUNDLE.md with collected proof

5. **Review Results**:
   - If all tests pass: proceed to production
   - If any test fails: execute rollback script

---

## Success Criteria

### Deployment Success
✅ Video variant deployed to separate S3 key  
✅ Baseline production build unchanged  
✅ CloudFront invalidation completed  
✅ Video URL accessible  
✅ No console errors on page load

### Functional Success
✅ SMS sends without video (baseline test)  
✅ SMS sends with video (new functionality)  
✅ Video capture failures are non-blocking  
✅ Video panel only appears in Step 4  
✅ Console logs show proof messages

### Rollback Success
✅ Rollback script executes without errors  
✅ Video URL inaccessible after rollback  
✅ Baseline production URL still works  
✅ No console errors after rollback

---

## Support and Documentation

### Checkpoint Reports
- **Checkpoint 9**: SMS composer integration (Task 9)
- **Checkpoint 10**: Backend compatibility check (Task 10)
- **Checkpoint 11**: E2E validation checklist (Task 11)
- **Checkpoint 12**: Release candidate packaging (Task 12)

### Proof Bundle
- **PROOF_BUNDLE.md**: Template for manual testing proof collection
- Fill during browser testing to document E2E validation

### Contact
For questions or issues, refer to checkpoint reports and proof bundle template.

---

**RC1 Status**: Ready for Manual Testing ✅  
**Next Step**: Execute E2E validation using PROOF_BUNDLE.md template

