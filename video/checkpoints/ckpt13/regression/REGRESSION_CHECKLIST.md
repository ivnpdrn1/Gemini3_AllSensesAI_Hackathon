# Regression Checklist - Video SMS Evidence Capture RC1

**Build ID**: `GEMINI3-GUARDIAN-SMS-VIDEO-20260201-v1`  
**Purpose**: Verify no regressions in baseline functionality after adding video features

---

## Critical Regression Tests

### 1. Step 1 Button Preservation
**Test**: Verify Step 1 button unchanged

**Expected State**:
- Button text: `✅ Complete Step 1`
- Button has `onclick="completeStep1()"`
- Button emoji (✅) renders correctly
- Clicking button enables Step 2

**Verification Method**:
1. Open DevTools → Elements
2. Inspect Step 1 button HTML
3. Verify exact text and onclick handler
4. Click button and verify Step 2 enables

**Pass Criteria**:
- [ ] Button text matches exactly: `✅ Complete Step 1`
- [ ] Button has `onclick="completeStep1()"`
- [ ] Emoji renders correctly (not corrupted)
- [ ] Clicking button enables Step 2

---

### 2. No Network Calls on Page Load
**Test**: Verify no video-related network calls at page load

**Expected Behavior**:
- Only HTML file loads
- No CORS preflight (OPTIONS) requests
- No camera API calls
- No S3 upload attempts
- No video-related fetch/XHR

**Verification Method**:
1. Open DevTools → Network tab
2. Clear network log
3. Load page
4. Wait 5 seconds
5. Observe network requests

**Pass Criteria**:
- [ ] Only 1 network request (HTML file)
- [ ] No OPTIONS requests
- [ ] No video-related network calls
- [ ] No CORS errors in console

---

### 3. No Camera Prompt Before Step 4
**Test**: Verify camera permission not requested until Step 4 user action

**Expected Behavior**:
- No camera prompt on page load
- No camera prompt in Steps 1-3
- Camera prompt only after Step 4 video capture button clicked

**Verification Method**:
1. Load page
2. Complete Steps 1-3
3. Observe browser permission prompts
4. Verify no camera prompt until Step 4 capture button clicked

**Pass Criteria**:
- [ ] No camera prompt on page load
- [ ] No camera prompt in Steps 1-3
- [ ] Camera prompt only after Step 4 capture button clicked

---

### 4. SMS Baseline Without Video
**Test**: Verify SMS sends successfully without video capture

**Expected Behavior**:
- SMS payload does NOT include `videoEvidenceUrl` field
- SMS message text does NOT include video link
- Console log shows: `[SMS_VIDEO] no videoEvidenceUrl available`
- SMS sends successfully (HTTP 200)

**Verification Method**:
1. Complete Steps 1-3
2. Skip video capture in Step 4
3. Confirm emergency and send SMS
4. Check DevTools → Network → POST request
5. Verify payload and response

**Pass Criteria**:
- [ ] SMS payload does NOT include `videoEvidenceUrl`
- [ ] SMS message text does NOT include video link
- [ ] Console log: `[SMS_VIDEO] no videoEvidenceUrl available`
- [ ] HTTP 200 response
- [ ] SMS received on phone

---

### 5. Video Capture + SMS With Link
**Test**: Verify video capture and SMS with appended link

**Expected Behavior**:
- Video capture succeeds
- `window.__videoEvidenceUrl` is set
- SMS payload INCLUDES `videoEvidenceUrl` field
- SMS message text INCLUDES video link at end
- Console log shows: `[SMS_VIDEO] injecting videoEvidenceUrl`

**Verification Method**:
1. Complete Steps 1-3
2. Capture video in Step 4 (allow camera access)
3. Wait for capture to complete
4. Confirm emergency and send SMS
5. Check DevTools → Network → POST request
6. Verify payload includes video URL

**Pass Criteria**:
- [ ] Video capture succeeds (status badge: "Complete")
- [ ] `window.__videoEvidenceUrl` is set (check in console)
- [ ] SMS payload INCLUDES `videoEvidenceUrl` field
- [ ] SMS message text INCLUDES video link
- [ ] Console log: `[SMS_VIDEO] injecting videoEvidenceUrl`
- [ ] HTTP 200 response
- [ ] SMS received with video link

---

### 6. Failure Cases Non-Blocking
**Test**: Verify video failures never block SMS delivery

**Failure Scenarios**:
- Camera permission denied
- Camera not available
- Upload failure (simulated)
- URL generation failure (simulated)

**Expected Behavior**:
- Video status badge shows "Error"
- Non-blocking warning displayed
- SMS sends successfully WITHOUT video
- Console log shows fallback behavior

**Verification Method**:
1. Complete Steps 1-3
2. Deny camera permission when prompted
3. Confirm emergency and send SMS
4. Verify SMS sends despite video failure

**Pass Criteria**:
- [ ] Video status badge shows "Error"
- [ ] Non-blocking warning displayed
- [ ] SMS sends successfully (HTTP 200)
- [ ] SMS received without video link
- [ ] Console log shows graceful failure

---

### 7. CORS: No OPTIONS Preflight Until User Action
**Test**: Verify no CORS preflight requests until user triggers action

**Expected Behavior**:
- No OPTIONS requests on page load
- No OPTIONS requests in Steps 1-3
- OPTIONS requests only after user action (SMS send, video capture)

**Verification Method**:
1. Open DevTools → Network tab
2. Filter by "OPTIONS" method
3. Load page and complete Steps 1-3
4. Verify no OPTIONS requests
5. Trigger SMS send
6. Verify OPTIONS request appears (if needed)

**Pass Criteria**:
- [ ] No OPTIONS requests on page load
- [ ] No OPTIONS requests in Steps 1-3
- [ ] OPTIONS requests only after user action

---

## Additional Regression Checks

### 8. Step 2 Location Services
**Test**: Verify location services work unchanged

**Pass Criteria**:
- [ ] "Enable Location" button works
- [ ] "Use Demo Location" button works
- [ ] Console logs show proof sequence: `[STEP2][PROOF 1]`, `[STEP2][PROOF 2]`, `[STEP2][PROOF 3A/3B]`
- [ ] Location data included in SMS

---

### 9. Step 3 Voice Detection
**Test**: Verify voice detection works unchanged

**Pass Criteria**:
- [ ] "Start Voice Detection" button works
- [ ] Emergency keywords detected
- [ ] Console logs show voice detection events
- [ ] Step 4 triggers after keyword detection

---

### 10. Video Panel Isolation
**Test**: Verify video panel only appears in Step 4

**Pass Criteria**:
- [ ] Video panel NOT visible in Steps 1-3
- [ ] Video panel visible in Step 4
- [ ] Video panel does not interfere with existing UI

---

### 11. Console Errors
**Test**: Verify no console errors on page load or during normal flow

**Pass Criteria**:
- [ ] No console errors on page load
- [ ] No console errors in Steps 1-3
- [ ] No console errors in Step 4 (except expected video failures)

---

### 12. Build ID Verification
**Test**: Verify build ID displays correctly

**Pass Criteria**:
- [ ] Build ID: `GEMINI3-GUARDIAN-SMS-VIDEO-20260201-v1`
- [ ] Build ID visible in console logs
- [ ] Build ID included in SMS payload

---

## Regression Test Summary

**Total Tests**: 12  
**Critical Tests**: 7  
**Additional Tests**: 5

**Pass Threshold**: All critical tests must pass  
**Failure Action**: If any critical test fails, rollback immediately

---

## Test Execution Log

**Test Date**: `[FILL: YYYY-MM-DD HH:MM:SS]`  
**Tester**: `[FILL: Your Name]`  
**Environment**: `[FILL: Local/Staging/Production]`  
**Browser**: `[FILL: Chrome/Firefox/Safari + Version]`

### Results Summary
```
[FILL: Test results]
Example:
- Tests Passed: 12/12
- Tests Failed: 0/12
- Critical Failures: 0
- Regressions Found: 0
```

### Failed Tests (if any)
```
[FILL: List failed tests with details]
Example:
1. Test 4 (SMS Baseline): FAILED - videoEvidenceUrl field present when it should not be
   - Expected: No videoEvidenceUrl field
   - Actual: videoEvidenceUrl: null
   - Action: Fix SMS composer logic
```

### Recommendations
```
[FILL: Recommendations based on test results]
Example:
1. All tests passed - proceed to production deployment
2. Monitor SMS delivery rates closely
3. Set up CloudWatch alarms for video capture failures
```

---

**Regression Status**: `[FILL: PASS/FAIL]`  
**Deployment Recommendation**: `[FILL: PROCEED/ROLLBACK/FIX REQUIRED]`
