# Runtime Verification Checklist

**Document Purpose**: Comprehensive checklist for verifying GEMINI Guardian deployment in production.

**Build**: GEMINI3-E164-PARITY-20260128  
**URL**: https://d3pbubsw4or36l.cloudfront.net  
**Audience**: Jury walkthroughs, QA testing, deployment verification

---

## Pre-Verification Setup

### Browser Requirements
- [ ] Chrome or Edge browser (recommended for full feature support)
- [ ] JavaScript enabled
- [ ] Cookies enabled
- [ ] Microphone available (for Step 3 testing)
- [ ] Location services enabled (for Step 2 testing)

### Network Requirements
- [ ] Internet connection active
- [ ] No corporate firewall blocking CloudFront
- [ ] No VPN interfering with geolocation
- [ ] DNS resolution working

### Preparation Steps
1. Open browser in normal mode (not incognito)
2. Navigate to: https://d3pbubsw4or36l.cloudfront.net
3. Hard refresh: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)
4. Wait for page to fully load
5. Open browser console (F12) for proof logging

---

## Section 1: UI Load Verification

### Page Load
- [ ] Page loads without errors
- [ ] No 404 or 500 errors
- [ ] No JavaScript errors in console
- [ ] Page renders completely
- [ ] No missing images or broken links

### Header Section
- [ ] "AllSensesAI Gemini3 Guardian" heading visible
- [ ] "Gemini 1.5 Pro | Emergency Detection System" subtitle visible
- [ ] Build stamp visible: **GEMINI3-E164-PARITY-20260128**
- [ ] Build stamp color: Blue background (#4285f4)
- [ ] "GEMINI3 POWERED" banner visible
- [ ] Banner color: Green background (#e8f5e9)

### Runtime Health Panel
- [ ] "🔍 Runtime Health Check" heading visible
- [ ] 4 health items displayed in grid
- [ ] Gemini3 Client: Shows "Initializing..." or "DEMO"
- [ ] Model: Shows "gemini-1.5-pro"
- [ ] Pipeline State: Shows "IDLE"
- [ ] Location Services: Shows "Not Started"

### All Steps Visible
- [ ] Step 1: Configuration section visible
- [ ] Step 2: Location Services section visible
- [ ] Step 3: Voice Emergency Detection section visible
- [ ] Step 4: Gemini3 Threat Analysis section visible
- [ ] Step 5: Emergency Alerting section visible

---

## Section 2: Step 1 Configuration

### Phone Input Field
- [ ] Input field visible and enabled
- [ ] Placeholder text: **+1XXXXXXXXXX, +57XXXXXXXXXX, +52XXXXXXXXXX, +58XXXXXXXXXX**
- [ ] Input type: tel
- [ ] Default value: +1234567890 (or empty)

### Helper Text
- [ ] Helper text visible below input
- [ ] Text: "Use E.164 format: +<countrycode><number> (examples: +1…, +57…, +52…, +58…)"
- [ ] Text color: Grey (#666)
- [ ] Font size: 0.9em

### International Support Note
- [ ] Note visible below helper text
- [ ] Background: Light blue (#f0f8ff)
- [ ] Border: Left border blue (#4a90e2)
- [ ] Text: "**International supported:** US (+1), Colombia (+57), Mexico (+52), Venezuela (+58)"

### Validation Feedback Div
- [ ] Div exists (id="phoneValidationFeedback")
- [ ] Initially hidden (display: none)
- [ ] Becomes visible after first input

### Name Input Field
- [ ] Input field visible and enabled
- [ ] Placeholder: "Your Name"
- [ ] Default value: "Demo User" (or empty)

### Complete Step 1 Button
- [ ] Button visible
- [ ] Button text: "✅ Complete Step 1"
- [ ] Button color: Green gradient
- [ ] Button enabled (not disabled)

### Status Message
- [ ] Status div visible (id="step1Status")
- [ ] Initial text: "Enter your details and click Complete Step 1"
- [ ] Text color: Grey

---

## Section 3: Phone Validation Testing

### Test Case 1: Valid US Number
**Input**: +14155552671

- [ ] Type number into phone field
- [ ] Validation feedback appears
- [ ] Feedback text: "✓ Valid E.164 (US)"
- [ ] Feedback color: Green (#28a745)
- [ ] No error alert

### Test Case 2: Valid Colombia Number
**Input**: +573001234567

- [ ] Type number into phone field
- [ ] Validation feedback appears
- [ ] Feedback text: "✓ Valid E.164 (Colombia)"
- [ ] Feedback color: Green (#28a745)
- [ ] No error alert

### Test Case 3: Valid Mexico Number
**Input**: +5215512345678

- [ ] Type number into phone field
- [ ] Validation feedback appears
- [ ] Feedback text: "✓ Valid E.164 (Mexico)"
- [ ] Feedback color: Green (#28a745)
- [ ] No error alert

### Test Case 4: Valid Venezuela Number
**Input**: +584121234567

- [ ] Type number into phone field
- [ ] Validation feedback appears
- [ ] Feedback text: "✓ Valid E.164 (Venezuela)"
- [ ] Feedback color: Green (#28a745)
- [ ] No error alert

### Test Case 5: Invalid - Missing Plus
**Input**: 14155552671

- [ ] Type number into phone field
- [ ] Validation feedback appears
- [ ] Feedback text: "Must start with + (E.164 format)"
- [ ] Feedback color: Red (#dc3545)
- [ ] Click "Complete Step 1"
- [ ] Alert appears: "Invalid phone number: Must start with + (E.164 format)"
- [ ] Form submission blocked

### Test Case 6: Invalid - Too Short
**Input**: +1

- [ ] Type number into phone field
- [ ] Validation feedback appears
- [ ] Feedback text: "Invalid E.164 format. Use +<countrycode><number> (7-15 digits total)"
- [ ] Feedback color: Red (#dc3545)
- [ ] Click "Complete Step 1"
- [ ] Alert appears with error message
- [ ] Form submission blocked

### Test Case 7: Invalid - Spaces
**Input**: +57 3001234567

- [ ] Type number into phone field
- [ ] Validation feedback appears
- [ ] Feedback text: "Invalid E.164 format. Use +<countrycode><number> (7-15 digits total)"
- [ ] Feedback color: Red (#dc3545)
- [ ] Click "Complete Step 1"
- [ ] Alert appears with error message
- [ ] Form submission blocked

### Test Case 8: Invalid - Dashes
**Input**: +52-55-1234-5678

- [ ] Type number into phone field
- [ ] Validation feedback appears
- [ ] Feedback text: "Invalid E.164 format. Use +<countrycode><number> (7-15 digits total)"
- [ ] Feedback color: Red (#dc3545)
- [ ] Click "Complete Step 1"
- [ ] Alert appears with error message
- [ ] Form submission blocked

---

## Section 4: Step 1 Completion

### Valid Number Submission
**Setup**: Enter valid number (e.g., +14155552671) and name

- [ ] Click "Complete Step 1" button
- [ ] No alert appears
- [ ] Status message changes to "✅ Configuration saved"
- [ ] Status message color: Green
- [ ] Pipeline State updates to "STEP1_COMPLETE"
- [ ] Step 2 "Enable Location" button becomes enabled

---

## Section 5: Step 2 Location Services

### Initial State
- [ ] "📍 Step 2 — Location Services" heading visible
- [ ] GPS Status box visible
- [ ] GPS Status: "📍 Click Enable Location to start"
- [ ] Last Update: "Never"
- [ ] Accuracy: "Unknown"
- [ ] "Enable Location" button disabled (until Step 1 complete)
- [ ] "Use Demo Location" button enabled
- [ ] Proof logging box visible
- [ ] Proof log text: "Complete Step 1, then click 'Enable Location' to see proof logs appear here..."

### After Step 1 Complete
- [ ] "Enable Location" button becomes enabled
- [ ] Button color: Green gradient
- [ ] Proof log updates: "Step 1 complete! Now click 'Enable Location' to see proof logs..."

### Demo Location Test
**Action**: Click "Use Demo Location"

- [ ] GPS Status changes to "✅ Active (Demo Mode)"
- [ ] Last Update shows current time
- [ ] Accuracy shows "±10m (Demo)"
- [ ] Location Health updates to "Demo Mode"
- [ ] Pipeline State updates to "STEP2_COMPLETE"
- [ ] Selected Location Panel appears
- [ ] Panel background: Light green (#e8f5e9)
- [ ] Panel border: Green (#4caf50)
- [ ] Latitude: 37.774900
- [ ] Longitude: -122.419400
- [ ] Source: "Demo Location"
- [ ] Timestamp: Current time
- [ ] Location Label: "San Francisco, CA (Demo)"
- [ ] Google Maps link visible and clickable
- [ ] Maps link opens in new tab
- [ ] Maps URL: https://www.google.com/maps?q=37.774900,-122.419400
- [ ] Proof log shows demo location activation
- [ ] Step 3 "Start Voice Detection" button becomes enabled

### Enable Location Test (Optional - Requires GPS)
**Action**: Click "Enable Location"

**Note**: This test requires GPS hardware and may timeout on desktop

- [ ] GPS Status changes to "🔄 Requesting permission..."
- [ ] Location Health updates to "Requesting..."
- [ ] Browser permission prompt appears
- [ ] Proof log shows: "[STEP2][PROOF 1] Click handler reached"
- [ ] Proof log shows: "[STEP2][PROOF 2] Calling navigator.geolocation.getCurrentPosition()"

**If Permission Granted and GPS Available**:
- [ ] Proof log shows: "[STEP2][PROOF 3A] SUCCESS [lat], [lng]"
- [ ] GPS Status changes to "✅ Active (Real GPS)"
- [ ] Last Update shows current time
- [ ] Accuracy shows "±[X]m"
- [ ] Location Health updates to "Active"
- [ ] Pipeline State updates to "STEP2_COMPLETE"
- [ ] Selected Location Panel appears with real coordinates
- [ ] Google Maps link generated with real coordinates

**If Permission Denied**:
- [ ] Proof log shows: "[STEP2][PROOF 3B] ERROR 1, User denied Geolocation"
- [ ] GPS Status changes to "❌ Location blocked"
- [ ] Proof log shows guidance: "Check browser settings → Location → Allow"
- [ ] Proof log shows fallback: "Demo Location available"
- [ ] Demo Location button remains available

**If Timeout (35 seconds)**:
- [ ] Proof log shows: "[STEP2][PROOF 3B] ERROR 3, Timeout expired"
- [ ] GPS Status changes to "⏱️ Location timeout"
- [ ] Proof log shows guidance: "Location timeout hit → fallback to Demo Location"
- [ ] Demo Location button remains available

---

## Section 6: Step 3 Voice Emergency Detection

### Initial State
- [ ] "🎤 Step 3 — Voice Emergency Detection" heading visible
- [ ] Microphone status badge visible
- [ ] Badge text: "Idle"
- [ ] Badge color: Grey (#e9ecef)
- [ ] "Start Voice Detection" button disabled (until Step 2 complete)
- [ ] "Stop Listening" button hidden
- [ ] "Clear Transcript" button hidden
- [ ] Status text: "Complete Steps 1 & 2 to enable voice detection"
- [ ] Transcript box hidden
- [ ] Proof box hidden

### After Step 2 Complete
- [ ] "Start Voice Detection" button becomes enabled
- [ ] Button color: Green gradient
- [ ] Status text: "✅ Ready - Click Start Voice Detection"
- [ ] Proof box becomes visible

### Start Voice Detection
**Action**: Click "Start Voice Detection"

**Note**: Requires microphone permission

- [ ] Badge changes to "Requesting Permission"
- [ ] Badge color: Yellow (#fff3cd)
- [ ] Browser microphone permission prompt appears
- [ ] Proof log shows: "[STEP3][EVENT] Mic permission requested"

**If Permission Granted**:
- [ ] Badge changes to "🎤 Listening"
- [ ] Badge color: Green (#d4edda) with pulse animation
- [ ] "Start Voice Detection" button hides
- [ ] "Stop Listening" button appears
- [ ] "Clear Transcript" button appears
- [ ] Transcript box appears
- [ ] Transcript shows: "(listening...)"
- [ ] Pipeline State updates to "STEP3_LISTENING"
- [ ] Proof log shows: "[STEP3][EVENT] Listening started"

**If Permission Denied**:
- [ ] Alert appears: "Microphone permission denied. Please allow microphone access in browser settings."
- [ ] Badge changes to "Error"
- [ ] Badge color: Red (#f8d7da)
- [ ] Proof log shows: "[STEP3][ERROR] not-allowed"

### Live Transcription Test
**Action**: Speak into microphone

**Note**: Requires Web Speech API (Chrome/Edge)

- [ ] Interim results appear in grey italic
- [ ] Final results appear in transcript lines
- [ ] Each line has timestamp
- [ ] Transcript auto-scrolls to bottom
- [ ] Proof log shows transcript snippets

### Emergency Keyword Test
**Action**: Say "help" or "emergency"

- [ ] Emergency modal appears immediately
- [ ] Modal heading: "🚨 Emergency Detected"
- [ ] Modal text: "Escalation sequence started"
- [ ] Modal text: "Locking in live location updates"
- [ ] Modal shows detected phrase
- [ ] Modal button: "Proceed to Threat Analysis"
- [ ] Emergency banner appears at top
- [ ] Banner background: Red gradient with pulse
- [ ] Banner heading: "🚨 EMERGENCY TRIGGERED"
- [ ] Banner shows timestamp
- [ ] Banner shows detected phrase
- [ ] Banner shows location
- [ ] Banner shows coordinates
- [ ] Banner shows Google Maps link
- [ ] Badge changes to "🚨 EMERGENCY DETECTED"
- [ ] Badge color: Red (#dc3545) with pulse
- [ ] Listening auto-stops
- [ ] Proof log shows: "[STEP3][TRIGGER] Emergency keyword detected: [keyword]"
- [ ] Proof log shows: "[STATE] Emergency workflow started"
- [ ] Modal auto-closes after 2 seconds
- [ ] System auto-advances to Step 4
- [ ] Step 4 textarea populated with emergency transcript

### Stop Listening Test
**Action**: Click "Stop Listening"

- [ ] Badge changes to "Stopped"
- [ ] Badge color: Red (#f8d7da)
- [ ] "Stop Listening" button hides
- [ ] "Start Voice Detection" button reappears
- [ ] Transcript remains visible
- [ ] "(listening...)" indicator removed
- [ ] Proof log shows: "[STEP3][EVENT] Listening stopped"

### Clear Transcript Test
**Action**: Click "Clear Transcript"

- [ ] Transcript content clears
- [ ] Only "(listening...)" remains (if still listening)
- [ ] Proof log shows: "[STEP3][ACTION] Transcript cleared"

---

## Section 7: Step 4 Gemini3 Threat Analysis

### Vision Context Panel (Always Visible)
- [ ] "🎥 Visual Context (Gemini Vision) — Video Frames" heading visible
- [ ] Panel background: Light blue (#f0f8ff)
- [ ] Panel border: Blue (#4a90e2)
- [ ] Status badge: "Standby"
- [ ] Badge color: Grey (#e9ecef)
- [ ] Explainer text visible
- [ ] Explainer mentions: "Activates automatically during detected risk"
- [ ] Explainer mentions: "Captures 1–3 video frames during emergency"
- [ ] "📹 Video Frames (Standby)" heading visible
- [ ] 3 frame placeholders visible
- [ ] Each placeholder: Grey box with dashed border
- [ ] Each placeholder text: "Frame X not captured"
- [ ] Placeholder dimensions: 120px × 90px
- [ ] Findings placeholder: "—"
- [ ] Confidence placeholder: "—"
- [ ] Vision/Video Status: "Standby"
- [ ] "Why this helps" text visible

### Threat Analysis Input
- [ ] Textarea visible
- [ ] Textarea placeholder: "Enter emergency text..."
- [ ] Default text: "Help! Someone is following me and I'm scared!"
- [ ] "Analyze with Gemini3" button visible
- [ ] Button color: Red gradient
- [ ] Button text: "🤖 Analyze with Gemini3"

### Manual Threat Analysis Test
**Action**: Click "Analyze with Gemini3"

- [ ] Gemini3 Client status changes to "Analyzing..."
- [ ] Pipeline State changes to "STEP4_ANALYZING"
- [ ] Warning message appears: "🤖 Gemini3 is analyzing the situation..."
- [ ] Analysis completes in ~1.5 seconds
- [ ] Threat Level Output box appears
- [ ] Threat Level displayed (e.g., "HIGH")
- [ ] Threat Level color matches level (HIGH = orange)
- [ ] Confidence displayed (e.g., "85%")
- [ ] Analysis text displayed
- [ ] Result box appears with summary
- [ ] Gemini3 Client status changes to "Analysis Complete"
- [ ] Pipeline State changes to "STEP4_COMPLETE"

### Auto-Advance Test (HIGH/CRITICAL Threat)
**Setup**: Ensure threat level is HIGH or CRITICAL

- [ ] Wait 1 second after analysis complete
- [ ] System auto-advances to Step 5
- [ ] Step 5 status changes to "🚨 Sending emergency alerts..."
- [ ] Pipeline State changes to "STEP5_ALERTING"

---

## Section 8: Step 5 Emergency Alerting

### Initial State
- [ ] "🚨 Step 5 — Emergency Alerting" heading visible
- [ ] Status text: "Waiting for threat analysis..."
- [ ] Alert result box hidden

### After HIGH/CRITICAL Threat
**Setup**: Complete Step 4 with HIGH or CRITICAL threat

- [ ] Status changes to "🚨 Sending emergency alerts..."
- [ ] Wait ~1 second
- [ ] Alert result box appears
- [ ] Box background: Light green (#d4edda)
- [ ] Box border: Green (#28a745)
- [ ] Heading: "✅ Alert Sent!"
- [ ] Details show emergency contact number
- [ ] Details show location label
- [ ] Details show coordinates
- [ ] Details show threat level
- [ ] Details show timestamp
- [ ] Status changes to "✅ Emergency alerts sent successfully"
- [ ] Pipeline State changes to "STEP5_COMPLETE"

---

## Section 9: Emergency UI Components

### Emergency Banner
**Trigger**: Emergency keyword detected in Step 3

- [ ] Banner appears at top of page
- [ ] Banner background: Red gradient (#dc3545 to #c82333)
- [ ] Banner border: Dark red (#a71d2a)
- [ ] Banner has pulse animation
- [ ] Heading: "🚨 EMERGENCY TRIGGERED"
- [ ] Timestamp displayed
- [ ] Detected phrase displayed (first 100 chars)
- [ ] Location label displayed
- [ ] Coordinates displayed
- [ ] Google Maps link visible
- [ ] Maps link text: "🗺️ View Emergency Location on Google Maps"
- [ ] Maps link opens in new tab
- [ ] Maps URL correct: https://www.google.com/maps?q=[lat],[lng]

### Emergency Modal
**Trigger**: Emergency keyword detected in Step 3

- [ ] Modal appears (full-screen overlay)
- [ ] Modal background: Dark semi-transparent (#000 80% opacity)
- [ ] Modal content: White box centered
- [ ] Modal heading: "🚨 Emergency Detected" (red text)
- [ ] Modal text: "Escalation sequence started"
- [ ] Modal text: "Locking in live location updates"
- [ ] Detected phrase displayed in italic red
- [ ] Button: "Proceed to Threat Analysis"
- [ ] Button color: Red gradient
- [ ] Modal has slide-in animation
- [ ] Modal auto-closes after 2 seconds
- [ ] Clicking button closes modal immediately

---

## Section 10: Browser Compatibility

### Chrome/Edge (Full Support)
- [ ] All features working
- [ ] Voice detection working
- [ ] E.164 validation working
- [ ] Location services working
- [ ] Emergency UI working
- [ ] No console errors

### Firefox (Limited Voice Support)
- [ ] Page loads correctly
- [ ] E.164 validation working
- [ ] Location services working
- [ ] Emergency UI working
- [ ] Voice detection may show compatibility warning
- [ ] Transcript may not work (Web Speech API limited)

### Safari (Limited Voice Support)
- [ ] Page loads correctly
- [ ] E.164 validation working
- [ ] Location services working
- [ ] Emergency UI working
- [ ] Voice detection may show compatibility warning
- [ ] Transcript may not work (Web Speech API limited)

---

## Section 11: Console Proof Logging

### Step 2 Proof Sequence
**Expected in Console**:
```
[STEP2][PROOF 1] Click handler reached
[STEP2][PROOF 2] Calling navigator.geolocation.getCurrentPosition()
[STEP2][PROOF 3A] SUCCESS [lat], [lng]
```
OR
```
[STEP2][PROOF 3B] ERROR [code], [message]
```

- [ ] Proof 1 appears on button click
- [ ] Proof 2 appears immediately after
- [ ] Proof 3A or 3B appears within 35 seconds
- [ ] Timestamps visible for each log

### Step 3 Proof Sequence
**Expected in Console**:
```
[STEP3] Speech Recognition initialized
[STEP3] Starting voice detection
[STEP3][EVENT] Mic permission requested
[STEP3][EVENT] Listening started
[STEP3][TRANSCRIPT] "[text]"
[STEP3][TRIGGER] Emergency keyword detected: [keyword]
```

- [ ] Initialization log appears on page load
- [ ] Start log appears on button click
- [ ] Permission log appears immediately
- [ ] Listening log appears after permission granted
- [ ] Transcript logs appear during speech
- [ ] Trigger log appears on emergency keyword

---

## Section 12: Performance Verification

### Page Load Performance
- [ ] Page loads in < 3 seconds
- [ ] No render-blocking resources
- [ ] No layout shifts
- [ ] Smooth scrolling

### Validation Performance
- [ ] Validation feedback appears instantly (< 20ms)
- [ ] No lag during typing
- [ ] Color changes smooth
- [ ] No UI freezing

### Emergency Response Performance
- [ ] Keyword detection < 100ms
- [ ] Emergency modal appears < 200ms
- [ ] Emergency banner appears < 200ms
- [ ] Badge update < 200ms
- [ ] Total emergency response < 1 second

---

## Section 13: Regression Testing

### Previous Features Preserved
- [ ] Step 2 location services working
- [ ] Step 3 voice detection working
- [ ] Emergency banner working
- [ ] Emergency modal working
- [ ] Badge status updates working
- [ ] Auto-advance workflow working
- [ ] Proof logging working
- [ ] Runtime health panel working
- [ ] Gemini3 branding visible
- [ ] Build stamp correct
- [ ] Vision panel visible in Step 4

### No Breaking Changes
- [ ] No JavaScript errors in console
- [ ] No CSS rendering issues
- [ ] No broken links
- [ ] No missing images
- [ ] No functionality removed

---

## Section 14: Final Verification

### Build Stamp Confirmation
- [ ] Build stamp visible in header
- [ ] Build stamp text: **GEMINI3-E164-PARITY-20260128**
- [ ] Build stamp color: Blue (#4285f4)
- [ ] Build stamp font: Bold

### E.164 Parity Confirmation
- [ ] Phone placeholder shows 4 country formats
- [ ] Helper text mentions E.164 format
- [ ] International support note visible
- [ ] Validation feedback working
- [ ] Valid numbers accepted (US, Colombia, Mexico, Venezuela)
- [ ] Invalid numbers rejected
- [ ] Form blocking working

### Zero Regressions Confirmation
- [ ] All previous features working
- [ ] No new errors introduced
- [ ] Performance maintained
- [ ] UI consistency maintained

---

## Verification Summary

### Critical Items (Must Pass)
- [ ] Page loads successfully
- [ ] Build stamp correct: GEMINI3-E164-PARITY-20260128
- [ ] Phone placeholder shows 4 country formats
- [ ] E.164 validation working (green ✓ / red ✗)
- [ ] Form blocking working for invalid numbers
- [ ] Step 2 location services working (Demo mode minimum)
- [ ] Vision panel visible in Step 4
- [ ] Emergency workflow functional (Step 3 → Step 4 → Step 5)

### Important Items (Should Pass)
- [ ] Voice detection working (Chrome/Edge)
- [ ] Real GPS working (if hardware available)
- [ ] Emergency banner displaying correctly
- [ ] Emergency modal displaying correctly
- [ ] Google Maps links working
- [ ] Proof logging visible in console

### Optional Items (Nice to Have)
- [ ] Voice detection in Firefox/Safari
- [ ] Real GPS on desktop
- [ ] All test cases passing

---

## Troubleshooting Guide

### Issue: Page Not Loading
**Check**:
- Internet connection
- CloudFront URL correct
- DNS resolution working
- Browser cache (try hard refresh)

### Issue: Build Stamp Wrong
**Check**:
- Hard refresh (Ctrl+Shift+R)
- Wait 60 seconds for cache propagation
- Check CloudFront invalidation status

### Issue: Validation Not Working
**Check**:
- JavaScript enabled
- Console for errors
- Input field has correct ID
- Validation function loaded

### Issue: Voice Detection Not Working
**Check**:
- Browser supports Web Speech API (Chrome/Edge)
- Microphone permission granted
- Microphone hardware connected
- No other app using microphone

### Issue: Location Not Working
**Check**:
- Location permission granted
- GPS hardware available (or use Demo mode)
- No VPN interfering
- Browser supports Geolocation API

---

**Document Status**: Complete  
**Last Updated**: January 28, 2026  
**Audience**: Jury walkthroughs, QA engineers, deployment verification

**Recommended Usage**: Print this checklist and check off items during jury demonstration or deployment verification.
