# Checkpoint 13 Report - Regression Test Harness + Rollback Safety Upgrade

**Date**: 2026-02-01  
**Task**: Task 13 - Implement comprehensive regression testing  
**Status**: Complete ✅

---

## Overview

Checkpoint 13 delivers a **comprehensive regression test harness** for RC1, enabling repeatable verification that the baseline production file remains unchanged and no regressions are introduced by the video variant. Additionally, the rollback script has been upgraded with a **Force mode** for instant rollback without confirmation prompts.

---

## Deliverables

### 1. Regression Checklist
**File**: `regression/REGRESSION_CHECKLIST.md`

**Purpose**: Comprehensive manual testing checklist with 12 tests (7 critical, 5 additional)

**Critical Tests**:
1. **Step 1 Button Preservation** - Verify button text, emoji, onclick handler unchanged
2. **No Network Calls on Page Load** - Verify no video-related network calls at page load
3. **No Camera Prompt Before Step 4** - Verify camera permission not requested until Step 4 user action
4. **SMS Baseline Without Video** - Verify SMS sends successfully without video capture
5. **Video Capture + SMS With Link** - Verify video capture and SMS with appended link
6. **Failure Cases Non-Blocking** - Verify video failures never block SMS delivery
7. **CORS: No OPTIONS Preflight Until User Action** - Verify no CORS preflight requests until user triggers action

**Additional Tests**:
8. Step 2 Location Services
9. Step 3 Voice Detection
10. Video Panel Isolation
11. Console Errors
12. Build ID Verification

**Pass Threshold**: All critical tests must pass  
**Failure Action**: If any critical test fails, rollback immediately

---

### 2. Local Regression Script
**File**: `regression/run-regression-local.ps1`

**Purpose**: Verify baseline production file unchanged and compute hashes

**Functionality**:
- Computes SHA256 hash of baseline production file (`gemini3-guardian-production-sms.html`)
- Computes SHA256 hash of video variant file (`gemini3-guardian-production-sms-video.html`)
- Verifies baseline hash matches known checkpoint 1 hash
- Writes hashes to `regression/hashes.txt`
- Fails with non-zero exit code if baseline hash mismatch

**Known Baseline Hash** (from checkpoint 1):
```
015EC574E9E65D66FA5B0A120347EC9183411674DB465F20E0E48ED7108704A7
```

**Exit Codes**:
- `0` - Success (baseline verified, hashes written)
- `1` - Failure (baseline mismatch or file not found)

**Usage**:
```powershell
.\regression\run-regression-local.ps1
```

---

### 3. Deployment Regression Script
**File**: `regression/run-regression-deploy.ps1`

**Purpose**: Print test URLs and proof collection commands for manual testing

**Functionality**:
- Prints exact deployed URLs to test (baseline + video path)
- Prints step-by-step proof collection commands
- Appends timestamped test run header to PROOF_BUNDLE.md

**Usage**:
```powershell
.\regression\run-regression-deploy.ps1 `
    -CloudFrontDomain "example.cloudfront.net" `
    -BaselinePath "index.html" `
    -VideoPath "video/index.html"
```

**Output**:
- Test URLs for baseline and video variant
- Manual testing instructions (DevTools, console logs, network requests)
- Proof collection commands (console logs, network payload, screenshots)
- Timestamped test run header appended to PROOF_BUNDLE.md

---

### 4. Rollback Script Upgrade
**File**: `rollback-production-sms-video.ps1` (modified)

**New Feature**: **Force Mode** for instant rollback without confirmation prompt

**Usage**:
```powershell
# Safe mode (with confirmation prompt) - DEFAULT
.\rollback-production-sms-video.ps1 `
    -BucketName "your-s3-bucket" `
    -DistributionId "E1234567890ABC"

# Force mode (no confirmation prompt) - EMERGENCY
.\rollback-production-sms-video.ps1 `
    -BucketName "your-s3-bucket" `
    -DistributionId "E1234567890ABC" `
    -Force
```

**Force Mode Benefits**:
- Instant rollback in emergency situations
- No user interaction required
- Safe for automation and CI/CD pipelines
- Preserves baseline production build

**Safety**:
- Safe mode remains default (requires typing "ROLLBACK" to confirm)
- Force mode requires explicit `-Force` parameter
- Both modes verify baseline production still works after rollback

---

### 5. Updated Release Notes
**File**: `RELEASE_NOTES.md` (modified)

**New Section**: "Regression Test Harness"

**Documentation Added**:
- Overview of regression test harness
- Description of all 3 regression scripts
- Regression test workflow (5 steps)
- Known baseline hash from checkpoint 1
- Exit codes and error handling
- Force mode usage for rollback script

---

## Regression Test Workflow

### Step 1: Run Local Regression Test
```powershell
.\regression\run-regression-local.ps1
```
- Verifies baseline file unchanged
- Computes hashes for both files
- Writes hashes to `regression/hashes.txt`

### Step 2: Deploy to Staging/Production
```powershell
.\deploy-production-sms-video.ps1 -BucketName "..." -DistributionId "..."
```

### Step 3: Run Deployment Regression Test
```powershell
.\regression\run-regression-deploy.ps1 -CloudFrontDomain "..."
```
- Prints test URLs
- Prints proof collection commands
- Appends test run header to PROOF_BUNDLE.md

### Step 4: Execute Manual Tests
- Follow `regression/REGRESSION_CHECKLIST.md`
- Collect proof (console logs, network requests, screenshots)
- Fill PROOF_BUNDLE.md with collected proof

### Step 5: Review Results
- If all tests pass: proceed to production
- If any test fails: execute rollback script

---

## Verification

### Files Created
✅ `regression/REGRESSION_CHECKLIST.md` - 12 tests (7 critical, 5 additional)  
✅ `regression/run-regression-local.ps1` - Local hash verification script  
✅ `regression/run-regression-deploy.ps1` - Deployment test script  

### Files Modified
✅ `rollback-production-sms-video.ps1` - Added Force mode  
✅ `RELEASE_NOTES.md` - Added regression test harness section  

### Checkpoint Backup
✅ All RC1 files copied to `checkpoints/ckpt13/`  
✅ Checkpoint report created: `ckpt13-report.md`  

---

## Known Baseline Hash

**File**: `gemini3-guardian-production-sms.html`  
**SHA256**: `015EC574E9E65D66FA5B0A120347EC9183411674DB465F20E0E48ED7108704A7`  
**Source**: Checkpoint 1 (baseline production build)

**Verification**: Local regression script compares current baseline hash against this known hash to detect any modifications.

---

## Success Criteria

✅ Regression checklist includes all critical tests  
✅ Local regression script verifies baseline unchanged  
✅ Deployment regression script prints test URLs and commands  
✅ Rollback script supports Force mode for instant rollback  
✅ Release notes document regression test harness  
✅ All files backed up to checkpoint 13  

---

## Next Steps

1. **Execute Local Regression Test**:
   ```powershell
   .\regression\run-regression-local.ps1
   ```

2. **Deploy to Staging**:
   ```powershell
   .\deploy-production-sms-video.ps1 -BucketName "..." -DistributionId "..."
   ```

3. **Execute Deployment Regression Test**:
   ```powershell
   .\regression\run-regression-deploy.ps1 -CloudFrontDomain "..."
   ```

4. **Manual Testing**:
   - Follow `regression/REGRESSION_CHECKLIST.md`
   - Collect proof and fill PROOF_BUNDLE.md

5. **Review Results**:
   - If all tests pass: proceed to production
   - If any test fails: execute rollback script with `-Force`

---

**Checkpoint 13 Status**: Complete ✅  
**Task 13 Status**: Complete ✅  
**Next Task**: Task 14 - Create deployment and rollback scripts (already complete - scripts exist in RC1)

---

## Notes

- Regression test harness is **repeatable** and **scriptable**
- Local regression script provides **automated verification** of baseline preservation
- Deployment regression script provides **step-by-step guidance** for manual testing
- Force mode enables **instant rollback** in emergency situations
- All regression scripts use **ASCII-only characters** for Windows compatibility
- Regression checklist includes **pass/fail criteria** for each test
- Known baseline hash enables **cryptographic verification** of baseline preservation

