# SMS Preview Complete - Testing Guide

**Build**: `GEMINI3-SMS-PREVIEW-COMPLETE-20260128`  
**URL**: https://d3pbubsw4or36l.cloudfront.net

## Quick Test (5 minutes)

1. **Open URL** and hard refresh (Ctrl+Shift+R)
2. **Verify build stamp** in header: `GEMINI3-SMS-PREVIEW-COMPLETE-20260128`
3. **Check Step 5**: SMS Preview panel should be visible (even before completing steps)
4. **Complete Step 1**: Enter name and phone (+1234567890)
5. **Check SMS Preview**: Should show "Enable location in Step 2"
6. **Complete Step 2**: Click "Use Demo Location"
7. **Check SMS Preview**: Should show standby format with contact/location/time
8. **Type in Step 4**: Type "Help! I'm scared!"
9. **Check console**: Should see `[TRIGGER] Keyword matched: "help" (source: manual)`
10. **Check SMS Preview**: Should change to "🚨 EMERGENCY ALERT" format
11. **Run analysis**: Click "Analyze with Gemini3"
12. **Check SMS Preview**: Should include risk level and reasoning
13. **Verify checklist**: All items should have green checkmarks

## Detailed Test Cases

### TASK A: Always-Visible Panel

**Test 1.1: Panel Visibility**
- [ ] Open app
- [ ] Scroll to Step 5
- [ ] Verify SMS Preview panel is visible
- [ ] Verify panel shows error: "Add emergency contact in Step 1"

**Test 1.2: Standby States**
- [ ] Complete Step 1
- [ ] Verify error changes to: "Enable location in Step 2"
- [ ] Complete Step 2
- [ ] Verify error disappears
- [ ] Verify preview shows standby format

**Test 1.3: Preview Content**
- [ ] Verify preview shows: Contact, Location, Time
- [ ] Verify preview shows: "Standby: no emergency trigger detected yet."

### TASK B: Live Updates

**Test 2.1: Contact Number Updates**
- [ ] Complete Steps 1-2
- [ ] Note current contact in preview
- [ ] Change contact number in Step 1
- [ ] Verify preview updates immediately
- [ ] Try different E.164 formats (+57, +52, +58)

**Test 2.2: Victim Name Updates**
- [ ] Note current name in preview
- [ ] Change name in Step 1
- [ ] Verify preview updates immediately

**Test 2.3: Location Updates**
- [ ] Click "Enable Location" (if GPS available)
- [ ] Verify preview updates with new coordinates
- [ ] OR click "Use Demo Location"
- [ ] Verify preview updates with demo coordinates

**Test 2.4: Textarea Updates**
- [ ] Type in Step 4 textarea
- [ ] Verify preview updates as you type
- [ ] Delete text
- [ ] Verify preview updates

**Test 2.5: Analysis Updates**
- [ ] Run threat analysis
- [ ] Verify preview updates with risk level
- [ ] Verify preview updates with reasoning

### TASK C: Keyword Detection

**Test 3.1: Voice Keywords (Chrome only)**
- [ ] Complete Steps 1-2
- [ ] Start voice detection (Step 3)
- [ ] Say "help"
- [ ] Check console: `[TRIGGER] Keyword matched: "help" (source: voice)`
- [ ] Check Step 3 Trigger Rule: Last match should show "help"
- [ ] Say "emergency"
- [ ] Check console: `[TRIGGER] Keyword matched: "emergency" (source: voice)`
- [ ] Check Step 3 Trigger Rule: Last match should update

**Test 3.2: Manual Keywords**
- [ ] Type "help" in Step 4 textarea
- [ ] Check console: `[TRIGGER] Keyword matched: "help" (source: manual)`
- [ ] Check Step 4 Trigger Rule: Last match should show "help"
- [ ] Type "emergency"
- [ ] Check console: `[TRIGGER] Keyword matched: "emergency" (source: manual)`
- [ ] Check Step 4 Trigger Rule: Last match should update

**Test 3.3: All Keywords**
Test each keyword in Step 4 textarea:
- [ ] "emergency"
- [ ] "help"
- [ ] "call 911"
- [ ] "call police"
- [ ] "help me"
- [ ] "scared"
- [ ] "following"
- [ ] "danger"
- [ ] "attack"

**Test 3.4: Word Boundary Matching**
- [ ] Type "helping" → should NOT trigger "help"
- [ ] Type "I need help" → should trigger "help"
- [ ] Type "emergency!" → should trigger "emergency"
- [ ] Type "HELP" → should trigger "help" (case-insensitive)

**Test 3.5: Trigger Rule UI**
- [ ] Verify Step 3 Trigger Rule shows: "Emergency keywords enabled: emergency, help, ..."
- [ ] Verify Step 4 Trigger Rule shows: "Emergency keywords enabled: emergency, help, ..."
- [ ] After keyword match, verify "Last match" updates with keyword, time, and source

### TASK D: Emergency State

**Test 4.1: Standby Format**
- [ ] Complete Steps 1-2 (no keywords yet)
- [ ] Verify SMS Preview shows:
  - "Standby: no emergency trigger detected yet."
  - Contact name
  - Location coordinates
  - Timestamp

**Test 4.2: Emergency Format**
- [ ] Type "help" in Step 4 textarea
- [ ] Verify SMS Preview changes to:
  - "🚨 EMERGENCY ALERT"
  - Contact name
  - Risk level (after analysis)
  - Recommendation (after analysis)
  - Message snippet
  - Location coordinates
  - Google Maps link
  - Timestamp
  - Next action instruction

**Test 4.3: Checklist Updates**
- [ ] Before keyword: Verify checklist shows "Standby" for Risk/Message
- [ ] After keyword: Verify checklist shows green checkmarks for all items
- [ ] Verify checklist items:
  - Product identity: ✓
  - Risk summary: ✓ (or Standby)
  - Victim message: ✓ (or Standby)
  - Location coordinates: ✓
  - Google Maps link: ✓
  - Timestamp: ✓
  - Next action instruction: ✓

**Test 4.4: Message Content**
- [ ] Verify emergency message includes all required fields
- [ ] Verify Google Maps link format: `https://maps.google.com/?q=lat,lng`
- [ ] Verify timestamp format: HH:MM:SS
- [ ] Verify message is deterministic (same inputs = same output)

## Integration Test

**End-to-End Flow**
1. [ ] Open URL and hard refresh
2. [ ] Verify build stamp
3. [ ] Complete Step 1: Name + Phone
4. [ ] Verify SMS Preview: "Enable location in Step 2"
5. [ ] Complete Step 2: Demo Location
6. [ ] Verify SMS Preview: Standby format
7. [ ] Start voice detection (Step 3)
8. [ ] Say "Help! Someone is following me!"
9. [ ] Verify console logs for "help" and "following"
10. [ ] Verify Step 3 Trigger Rule updates
11. [ ] Stop voice detection
12. [ ] Go to Step 4 textarea
13. [ ] Type "I'm scared and don't feel safe"
14. [ ] Verify console logs for "scared"
15. [ ] Verify Step 4 Trigger Rule updates
16. [ ] Verify SMS Preview: Emergency Alert format
17. [ ] Run threat analysis
18. [ ] Verify SMS Preview includes risk/reasoning
19. [ ] Verify checklist: All green checkmarks
20. [ ] Send alert (Step 5)
21. [ ] Verify "Sent Message" panel
22. [ ] Verify sent message matches preview exactly

## Console Verification

Open browser console (F12) and verify logs:

```
[TRIGGER] Keyword matched: "help" (source: voice)
[TRIGGER] Keyword matched: "following" (source: voice)
[TRIGGER] Keyword matched: "scared" (source: manual)
[SMS-PREVIEW] Preview updated successfully (emergency: true)
```

## Expected Behavior

### Before Keyword Detection
- SMS Preview shows standby format
- Checklist shows "Standby" for Risk/Message
- Trigger Rule shows "Last match: None"

### After Keyword Detection
- SMS Preview shows Emergency Alert format
- Checklist shows green checkmarks for all items
- Trigger Rule shows "Last match: <keyword> at <time> (<source>)"
- Console shows `[TRIGGER] Keyword matched`

### After Threat Analysis
- SMS Preview includes risk level
- SMS Preview includes reasoning
- Checklist remains green
- Preview updates immediately

### After Send Alert
- "Sent Message" panel appears
- Sent message matches preview exactly
- Timestamp shows send time

## Troubleshooting

### SMS Preview Not Visible
- Hard refresh (Ctrl+Shift+R)
- Check build stamp
- Check browser console for errors

### Keywords Not Detected
- Check console for `[TRIGGER]` logs
- Verify word boundary matching (not "helping")
- Verify case-insensitive matching (HELP = help)

### Preview Not Updating
- Check browser console for errors
- Verify event listeners attached
- Check `updateSmsPreview()` calls

### Voice Detection Not Working
- Use Chrome browser
- Allow microphone permission
- Check console for speech recognition errors

## Success Criteria

✅ SMS Preview always visible  
✅ Standby states work correctly  
✅ Live updates on all input changes  
✅ Keywords detected in voice  
✅ Keywords detected in manual text  
✅ Trigger Rule UI updates  
✅ SMS format changes based on emergency state  
✅ Checklist updates correctly  
✅ Console logs show keyword matches  
✅ Sent message matches preview  

## Test Results Template

```
Date: ___________
Tester: ___________
Browser: ___________
Build: GEMINI3-SMS-PREVIEW-COMPLETE-20260128

TASK A: Always-Visible Panel
- Test 1.1: [ ] PASS [ ] FAIL
- Test 1.2: [ ] PASS [ ] FAIL
- Test 1.3: [ ] PASS [ ] FAIL

TASK B: Live Updates
- Test 2.1: [ ] PASS [ ] FAIL
- Test 2.2: [ ] PASS [ ] FAIL
- Test 2.3: [ ] PASS [ ] FAIL
- Test 2.4: [ ] PASS [ ] FAIL
- Test 2.5: [ ] PASS [ ] FAIL

TASK C: Keyword Detection
- Test 3.1: [ ] PASS [ ] FAIL
- Test 3.2: [ ] PASS [ ] FAIL
- Test 3.3: [ ] PASS [ ] FAIL
- Test 3.4: [ ] PASS [ ] FAIL
- Test 3.5: [ ] PASS [ ] FAIL

TASK D: Emergency State
- Test 4.1: [ ] PASS [ ] FAIL
- Test 4.2: [ ] PASS [ ] FAIL
- Test 4.3: [ ] PASS [ ] FAIL
- Test 4.4: [ ] PASS [ ] FAIL

Integration Test: [ ] PASS [ ] FAIL

Notes:
_________________________________
_________________________________
_________________________________
```
