# Gemini3 Guardian UX Enhancements - Verification Checklist

**Deployment Date**: January 27, 2026  
**Jury URL**: https://d3pbubsw4or36l.cloudfront.net  
**Build**: GEMINI3-UX-ENHANCED-20260127

## Pre-Demo Verification

### Step 1: Configuration
- [ ] Open URL: https://d3pbubsw4or36l.cloudfront.net
- [ ] Verify build stamp shows: "GEMINI3-UX-ENHANCED-20260127"
- [ ] Verify "GEMINI3 POWERED" banner visible
- [ ] Enter name and phone number
- [ ] Click "Complete Step 1"
- [ ] Verify status shows "✅ Configuration saved"

### Step 2: Location Services (NEW FEATURES)

#### Test A: Enable Location (Real GPS)
- [ ] Click "📍 Enable Location"
- [ ] Verify proof log shows:
  - `[STEP2][PROOF 1] Click handler reached`
  - `[STEP2][PROOF 2] Calling navigator.geolocation.getCurrentPosition()`
  - `[STEP2][PROOF 3A] SUCCESS` (if GPS available)
- [ ] **NEW**: Verify "Selected Location Panel" appears
- [ ] **NEW**: Verify panel shows:
  - Latitude (6 decimal places)
  - Longitude (6 decimal places)
  - Source: "Browser GPS"
  - Timestamp (current time)
  - Location Label (coordinates or "unavailable")
- [ ] **NEW**: Verify proof log shows:
  - `Location picked: lat=..., lng=..., source=Browser GPS, at=...`

#### Test B: Demo Location
- [ ] Click "🎯 Use Demo Location"
- [ ] **NEW**: Verify "Selected Location Panel" appears
- [ ] **NEW**: Verify panel shows:
  - Latitude: 37.774900
  - Longitude: -122.419400
  - Source: "Demo Location"
  - Timestamp (current time)
  - Location Label: "San Francisco, CA (Demo)"
- [ ] **NEW**: Verify proof log shows demo location details

### Step 3: Voice Emergency Detection (NEW FEATURES)

#### Test A: Microphone Status Badge
- [ ] **NEW**: Verify badge next to "Step 3" title
- [ ] **NEW**: Initial state shows "Idle" (gray)
- [ ] Click "🎤 Start Voice Detection"
- [ ] **NEW**: Badge changes to "Requesting Permission" (yellow)
- [ ] Grant microphone permission
- [ ] **NEW**: Badge changes to "🎤 Listening" (green, pulsing)
- [ ] Click "⏹️ Stop Listening"
- [ ] **NEW**: Badge changes to "Stopped" (red)

#### Test B: Live Transcript
- [ ] Click "🎤 Start Voice Detection"
- [ ] **NEW**: Verify "Live Transcript" box appears
- [ ] **NEW**: Verify shows "(listening...)" indicator
- [ ] Speak: "Help! Someone is following me"
- [ ] **NEW**: Verify transcript updates in real-time
- [ ] **NEW**: Verify interim results show (gray, italic)
- [ ] Stop speaking
- [ ] **NEW**: Verify finalized transcript appears with timestamp
- [ ] **NEW**: Format: `[10:30:45 AM] Help! Someone is following me`

#### Test C: Voice Controls
- [ ] **NEW**: Verify "Start Voice Detection" button visible initially
- [ ] Click Start
- [ ] **NEW**: Verify button changes to "Stop Listening"
- [ ] **NEW**: Verify "Clear Transcript" button appears
- [ ] Speak multiple phrases
- [ ] **NEW**: Verify transcript accumulates with timestamps
- [ ] Click "Clear Transcript"
- [ ] **NEW**: Verify transcript history cleared
- [ ] **NEW**: Verify "(listening...)" indicator remains

#### Test D: Proof Logging
- [ ] **NEW**: Verify "Step 3 Proof (Mic Events)" box visible
- [ ] **NEW**: Verify logs show:
  - `[STEP3][EVENT] Mic permission requested`
  - `[STEP3][EVENT] Mic permission granted`
  - `[STEP3][EVENT] Listening started`
  - `[STEP3][TRANSCRIPT] "..."`
  - `[STEP3][EVENT] Listening stopped`

#### Test E: Browser Compatibility
- [ ] If using Chrome/Edge: Full functionality works
- [ ] If using Firefox/Safari: Verify friendly message:
  - "Live transcription not supported in this browser. Please use Chrome."
- [ ] Verify rest of demo continues (no crash)

### Step 4: Gemini3 Threat Analysis
- [ ] Enter or use default emergency text
- [ ] Click "🤖 Analyze with Gemini3"
- [ ] Verify analysis completes
- [ ] Verify threat level displayed
- [ ] **NEW**: Verify location label used in analysis

### Step 5: Emergency Alerting
- [ ] If threat level HIGH/CRITICAL, verify auto-trigger
- [ ] Verify alert shows:
  - Emergency contact
  - **NEW**: Location label
  - **NEW**: Coordinates (lat/lng)
  - Threat level
  - Timestamp

## State Persistence Tests

### Test A: Location State
- [ ] Complete Step 2 (select location)
- [ ] Navigate to Step 3
- [ ] Navigate to Step 4
- [ ] Verify location still available in Step 4 analysis
- [ ] Verify location still available in Step 5 alert

### Test B: Transcript State
- [ ] Start voice detection
- [ ] Speak multiple phrases
- [ ] Stop listening
- [ ] Verify transcript preserved
- [ ] Start listening again
- [ ] Verify new transcript appends to history

### Test C: Page Reload
- [ ] Complete all steps
- [ ] Reload page (F5)
- [ ] Verify all state reset cleanly
- [ ] Verify no stale GPS values
- [ ] Verify no stale transcript

## Zero ERNIE Exposure Verification

- [ ] View page source (Ctrl+U)
- [ ] Search for "ERNIE" (case-insensitive)
- [ ] Verify 0 matches
- [ ] Search for "Baidu"
- [ ] Verify 0 matches
- [ ] Open DevTools → Network
- [ ] Verify no ERNIE endpoints
- [ ] Open DevTools → Console
- [ ] Verify no ERNIE logs
- [ ] Verify all logs show "GEMINI3" or "Gemini"

## Performance Tests

- [ ] Page loads in < 3 seconds
- [ ] Location request completes in < 35 seconds (or times out gracefully)
- [ ] Voice detection starts in < 2 seconds
- [ ] Transcript updates in real-time (< 500ms delay)
- [ ] Gemini3 analysis completes in < 3 seconds (demo mode)

## Mobile Compatibility (Optional)

- [ ] Test on mobile Chrome
- [ ] Verify location services work
- [ ] Verify voice detection works
- [ ] Verify UI responsive
- [ ] Verify touch interactions work

## Final Checklist

- [ ] All Step 2 enhancements working
- [ ] All Step 3 enhancements working
- [ ] No ERNIE references anywhere
- [ ] Gemini3 branding consistent
- [ ] No secrets exposed
- [ ] Demo mode functional
- [ ] Proof logging visible
- [ ] State management correct
- [ ] Browser compatibility handled
- [ ] Ready for jury demonstration

---

**Verification Status**: ⬜ NOT STARTED | 🟡 IN PROGRESS | ✅ COMPLETE  
**Verified By**: _________________  
**Date**: _________________  
**Notes**: _________________
