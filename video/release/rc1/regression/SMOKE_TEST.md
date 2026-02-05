# Smoke Test Checklist - Video SMS Evidence Capture RC1

**Purpose:** Manual browser-based verification of video variant runtime behavior

**Date:** 2026-02-01  
**Build:** GEMINI3-GUARDIAN-SMS-VIDEO-20260201-v1  
**Tester:** _____________  

---

## Pre-Test Setup

- [ ] Browser: Chrome/Edge (latest version)
- [ ] DevTools open (F12) with Console and Network tabs visible
- [ ] Clear browser cache (Ctrl+Shift+Delete)
- [ ] Baseline URL ready: `https://dfc8ght8abwqc.cloudfront.net/`
- [ ] Video URL ready: `https://dfc8ght8abwqc.cloudfront.net/video/index.html`

---

## Test Phase 1: Baseline Production URL (No Video)

**URL:** `https://dfc8ght8abwqc.cloudfront.net/`

### 1.1 Page Load Verification
- [ ] Page loads without errors
- [ ] Console shows NO errors (red text)
- [ ] Console shows NO warnings about missing files
- [ ] Network tab shows NO 403 errors
- [ ] Network tab shows NO 404 errors

### 1.2 Step 1 Button Verification
- [ ] Step 1 button text is "✅ Complete Step 1"
- [ ] Step 1 button has green styling
- [ ] Clicking Step 1 button enables Step 2
- [ ] Console shows `[STEP1] Complete Step 1 clicked`

### 1.3 Steps 2-3 Functional Parity
- [ ] Step 2 location services work (Enable Location button visible)
- [ ] Step 3 voice detection works (Start Voice button visible)
- [ ] No video-related UI elements visible in Steps 1-3

### 1.4 SMS Without Video (Baseline Behavior)
- [ ] Complete Steps 1-3 normally
- [ ] Trigger emergency in Step 4 (Gemini Vision confirms threat)
- [ ] SMS sends successfully
- [ ] SMS does NOT contain video URL
- [ ] Console shows `[STEP5] SMS sent successfully`

**Baseline Production Status:** ✅ PASS / ❌ FAIL

---

## Test Phase 2: Video Variant URL (With Video)

**URL:** `https://dfc8ght8abwqc.cloudfront.net/video/index.html`

### 2.1 Page Load Verification
- [ ] Page loads without errors
- [ ] Console shows NO SyntaxError
- [ ] Console shows NO ReferenceError
- [ ] Network tab shows NO 403 for JS modules:
  - [ ] `/video/VideoCaptureModule.js` → 200 OK
  - [ ] `/video/VideoStorageService.js` → 200 OK
  - [ ] `/video/SignedURLGenerator.js` → 200 OK
  - [ ] `/video/IntegrationOrchestrator.js` → 200 OK
- [ ] All JS files have Content-Type: `application/javascript`

### 2.2 No Camera Prompt on Page Load
- [ ] Browser does NOT prompt for camera permission on page load
- [ ] Video panel is NOT visible in Steps 1-3
- [ ] Console shows NO `[VIDEO]` logs during initialization

### 2.3 Step 1 Button Verification (Video Variant)
- [ ] Step 1 button text is "✅ Complete Step 1"
- [ ] Step 1 button has green styling
- [ ] Clicking Step 1 button enables Step 2
- [ ] Console shows `[STEP1] Complete Step 1 clicked`
- [ ] `completeStep1` function is defined (no ReferenceError)

### 2.4 Video Panel Appears in Step 4 Only
- [ ] Complete Steps 1-3 normally
- [ ] Video panel appears in Step 4 after emergency confirmation
- [ ] Video panel shows "Standby" status badge
- [ ] Video panel has explainer text about video evidence

### 2.5 Video Capture Triggers on Emergency Confirmation
- [ ] Trigger emergency in Step 4 (Gemini Vision confirms threat)
- [ ] Browser prompts for camera permission
- [ ] Console shows `[VIDEO] init`
- [ ] Console shows `[VIDEO] permission granted` (if allowed)
- [ ] Console shows `[VIDEO] capture started`
- [ ] Video panel status changes to "Capturing"
- [ ] Video panel shows animation (pulsing badge)

### 2.6 SMS With Video URL (Success Case)
- [ ] Allow camera permission
- [ ] Wait for capture to complete (3-5 seconds)
- [ ] Console shows `[VIDEO] capture completed`
- [ ] Console shows `[VIDEO] upload success`
- [ ] Video panel status changes to "Complete"
- [ ] Video panel shows thumbnails
- [ ] SMS sends successfully
- [ ] SMS contains video URL: "View video evidence (expires soon): https://..."
- [ ] Console shows `[STEP5] SMS sent successfully`

**Video Success Case Status:** ✅ PASS / ❌ FAIL

---

## Test Phase 3: Video Failure Handling (Non-Blocking)

**URL:** `https://dfc8ght8abwqc.cloudfront.net/video/index.html`

### 3.1 Camera Permission Denied
- [ ] Trigger emergency in Step 4
- [ ] Browser prompts for camera permission
- [ ] Click "Block" or "Deny" on camera prompt
- [ ] Console shows `[VIDEO] permission denied`
- [ ] Video panel status changes to "Error"
- [ ] Video panel shows non-blocking warning message
- [ ] SMS STILL sends successfully (video failure is non-fatal)
- [ ] SMS does NOT contain video URL
- [ ] Console shows `[STEP5] SMS sent successfully`

### 3.2 Upload Failure (Simulated)
- [ ] Trigger emergency in Step 4
- [ ] Allow camera permission
- [ ] Disconnect network during upload (DevTools → Network → Offline)
- [ ] Console shows `[VIDEO] upload failure`
- [ ] Video panel status changes to "Error"
- [ ] Video panel shows non-blocking warning message
- [ ] SMS STILL sends successfully (video failure is non-fatal)
- [ ] SMS does NOT contain video URL
- [ ] Console shows `[STEP5] SMS sent successfully`

**Video Failure Handling Status:** ✅ PASS / ❌ FAIL

---

## Test Phase 4: Regression Verification

### 4.1 No Console Errors on Page Load
- [ ] Baseline URL: NO console errors
- [ ] Video URL: NO console errors
- [ ] No SyntaxError in either build
- [ ] No ReferenceError in either build

### 4.2 No New CORS Calls During Initialization
- [ ] Baseline URL: No CORS preflight requests on page load
- [ ] Video URL: No CORS preflight requests on page load
- [ ] Video modules load from same origin (CloudFront)

### 4.3 Steps 1-3 Functional Parity
- [ ] Baseline URL: Steps 1-3 work identically
- [ ] Video URL: Steps 1-3 work identically
- [ ] No video-related UI in Steps 1-3 (video variant)

### 4.4 SMS Delivery Always Works
- [ ] Baseline URL: SMS sends successfully
- [ ] Video URL (camera allowed): SMS sends with video URL
- [ ] Video URL (camera denied): SMS sends without video URL
- [ ] Video URL (upload failed): SMS sends without video URL

**Regression Verification Status:** ✅ PASS / ❌ FAIL

---

## Test Phase 5: Network Proof Collection

### 5.1 Baseline Production Network Proof
- [ ] Screenshot of Network tab (baseline URL)
- [ ] Screenshot of Console tab (baseline URL)
- [ ] Verify no 403/404 errors
- [ ] Verify no video module requests

### 5.2 Video Variant Network Proof
- [ ] Screenshot of Network tab (video URL)
- [ ] Screenshot of Console tab (video URL)
- [ ] Verify all 4 JS modules load 200
- [ ] Verify Content-Type: application/javascript
- [ ] Verify no 403 errors

### 5.3 SMS Proof Collection
- [ ] Screenshot of SMS received (baseline - no video)
- [ ] Screenshot of SMS received (video - with link)
- [ ] Screenshot of SMS received (video - camera denied, no link)
- [ ] Verify SMS text format matches expected patterns

**Network Proof Status:** ✅ COMPLETE / ❌ INCOMPLETE

---

## Final Smoke Test Summary

| Test Phase | Status | Notes |
|------------|--------|-------|
| Baseline Production URL | ⬜ PASS / ⬜ FAIL | |
| Video Variant URL | ⬜ PASS / ⬜ FAIL | |
| Video Failure Handling | ⬜ PASS / ⬜ FAIL | |
| Regression Verification | ⬜ PASS / ⬜ FAIL | |
| Network Proof Collection | ⬜ COMPLETE / ⬜ INCOMPLETE | |

**Overall Status:** ⬜ READY FOR DEPLOYMENT / ⬜ NOT READY

**Tester Signature:** _____________  
**Date:** _____________  
**Time:** _____________  

---

## Troubleshooting Guide

### Issue: 403 Errors for JS Modules
**Symptom:** Network tab shows 403 for `/video/*.js` files  
**Cause:** JS modules not uploaded to S3 or wrong path  
**Fix:** Run deployment script with correct S3 keys

### Issue: SyntaxError on Page Load
**Symptom:** Console shows "Uncaught SyntaxError: Unexpected token 'function'"  
**Cause:** 403 error returns HTML, browser tries to parse as JS  
**Fix:** Verify JS modules uploaded with correct Content-Type

### Issue: completeStep1 is not defined
**Symptom:** Console shows "Uncaught ReferenceError: completeStep1 is not defined"  
**Cause:** Script execution aborted due to earlier SyntaxError  
**Fix:** Resolve 403 errors first, then reload page

### Issue: Camera Prompt on Page Load
**Symptom:** Browser prompts for camera immediately on page load  
**Cause:** Video capture triggered too early  
**Fix:** Verify video capture only triggers after Step 4 emergency confirmation

### Issue: SMS Not Sending
**Symptom:** SMS delivery fails regardless of video status  
**Cause:** Backend Lambda issue or network connectivity  
**Fix:** Check Lambda logs, verify network connectivity, test baseline URL

---

## Expected Console Log Patterns

### Baseline Production (No Video)
```
[STEP1] Complete Step 1 clicked
[STEP2][PROOF 1] Click handler reached
[STEP2][PROOF 2] Calling navigator.geolocation.getCurrentPosition()
[STEP2][PROOF 3A] SUCCESS lat, lng
[STEP3] Voice detection started
[STEP4] Emergency confirmed by Gemini Vision
[STEP5] SMS sent successfully
```

### Video Variant (Camera Allowed)
```
[STEP1] Complete Step 1 clicked
[STEP2][PROOF 1] Click handler reached
[STEP2][PROOF 2] Calling navigator.geolocation.getCurrentPosition()
[STEP2][PROOF 3A] SUCCESS lat, lng
[STEP3] Voice detection started
[STEP4] Emergency confirmed by Gemini Vision
[VIDEO] init
[VIDEO] permission granted
[VIDEO] capture started
[VIDEO] capture completed
[VIDEO] upload success
[STEP5] SMS sent successfully (with video URL)
```

### Video Variant (Camera Denied)
```
[STEP1] Complete Step 1 clicked
[STEP2][PROOF 1] Click handler reached
[STEP2][PROOF 2] Calling navigator.geolocation.getCurrentPosition()
[STEP2][PROOF 3A] SUCCESS lat, lng
[STEP3] Voice detection started
[STEP4] Emergency confirmed by Gemini Vision
[VIDEO] init
[VIDEO] permission denied
[STEP5] SMS sent successfully (without video URL)
```

---

**End of Smoke Test Checklist**
