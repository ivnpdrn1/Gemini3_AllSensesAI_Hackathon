# Step 1 Fix + Keywords Field Testing Guide

**Build:** `GEMINI3-STEP1-KEYWORDS-FIX-20260128`  
**CloudFront URL:** https://d3pbubsw4or36l.cloudfront.net  
**Testing Date:** January 28, 2026

---

## Quick Start

1. Open https://d3pbubsw4or36l.cloudfront.net
2. Hard refresh: **Ctrl+Shift+R** (Windows) or **Cmd+Shift+R** (Mac)
3. Verify build stamp: `GEMINI3-STEP1-KEYWORDS-FIX-20260128`
4. Open browser console (F12) to see logs

---

## Test Suite

### ✅ Test 1: Step 1 Button Click Progression

**Objective:** Verify Step 1 button click works and unlocks Step 2

**Steps:**
1. Enter name: `Demo User`
2. Enter phone: `+1234567890`
3. Click "Complete Step 1" button
4. Observe Step 1 proof box
5. Check Step 1 status
6. Check Step 2 "Enable Location" button

**Expected Results:**

**Step 1 Proof Box:**
```
[STEP1] Click received
[STEP1] Name: provided
[STEP1] Phone: provided
[STEP1] Phone valid: true
[STEP1] Configuration saved
[STEP1] Step 2 unlocked
[STEP1] Pipeline state: STEP1_COMPLETE
```

**Step 1 Status:**
```
Configuration saved
```

**Step 2:**
- "Enable Location" button is **enabled** (not grayed out)
- Step 2 proof box shows: "Step 1 complete! Now click 'Enable Location' to see proof logs..."

**Console Logs:**
```
[STEP1] Button click handler bound
[STEP1] Click received
[STEP1] Phone valid: true
[STEP1] Configuration saved
[STEP1] Step 2 unlocked
[STEP1] Pipeline state: STEP1_COMPLETE
[STEP1] Step 1 complete - Step 2 and Step 3 will unlock after location
```

**Pass Criteria:**
- ✅ Step 1 proof box shows all logs
- ✅ Step 1 status: "Configuration saved"
- ✅ Step 2 "Enable Location" button enabled
- ✅ No console errors

---

### ✅ Test 2: Step 1 E.164 Phone Validation

**Objective:** Verify phone validation works correctly

**Test Cases:**

| Phone Number | Expected Result | Reason |
|--------------|----------------|--------|
| `+1234567890` | ✅ Valid | US format |
| `+573001234567` | ✅ Valid | Colombia format |
| `+525512345678` | ✅ Valid | Mexico format |
| `+584121234567` | ✅ Valid | Venezuela format |
| `1234567890` | ❌ Invalid | Missing + |
| `+1234` | ❌ Invalid | Too short |
| `+12345678901234567` | ❌ Invalid | Too long |
| `+0123456789` | ❌ Invalid | Starts with 0 |

**Steps:**
1. Enter each phone number
2. Click "Complete Step 1"
3. Observe validation result

**Expected Results:**
- Valid numbers: Step 1 completes successfully
- Invalid numbers: Alert message with error

**Pass Criteria:**
- ✅ All valid numbers accepted
- ✅ All invalid numbers rejected with clear error message

---

### ✅ Test 3: Add Custom Keywords

**Objective:** Verify custom keywords can be added

**Steps:**
1. Complete Steps 1 and 2
2. Scroll to Step 3
3. Find "Add Emergency Keywords" section
4. Enter: `knife, stop following me, danger`
5. Click "Add Keywords" button
6. Observe status message
7. Check Trigger Rule UI

**Expected Results:**

**Status Message:**
```
Added 3 new keyword(s). Total: 12 keywords.
```
(Message disappears after 3 seconds)

**Trigger Rule UI (Step 3 and Step 4):**
```
🔔 Trigger Rule
Emergency keywords enabled: emergency, help, call 911, call police, help me, scared, following, danger, attack, knife, stop following me...
Last match: None
```

**Console Logs:**
```
[KEYWORDS] Added keywords: ["knife", "stop following me", "danger"]
[KEYWORDS] Total keywords: 12
[KEYWORDS] Saved custom keywords to localStorage: ["knife", "stop following me", "danger"]
```

**Pass Criteria:**
- ✅ Status message appears with correct count
- ✅ Trigger Rule UI shows new keywords
- ✅ Console logs confirm keywords added
- ✅ No duplicate keywords

---

### ✅ Test 4: Keyword Detection in Voice (Step 3)

**Objective:** Verify keywords detected in voice transcript

**Prerequisites:**
- Microphone access granted
- Steps 1 and 2 completed

**Steps:**
1. Click "Start Voice Detection" in Step 3
2. Say: "Help! Someone is following me!"
3. Observe console logs
4. Check Trigger Rule UI
5. Check emergency banner

**Expected Results:**

**Console Logs:**
```
[TRIGGER] Keyword matched: "help" (source: voice)
[TRIGGER] Keyword matched: "following" (source: voice)
```

**Trigger Rule UI:**
```
🔔 Trigger Rule
Emergency keywords enabled: emergency, help, call 911, call police, help me, scared, following, danger, attack...
Last match: help at 10:30:45 AM
```

**Emergency Banner:**
- Appears at top of page
- Shows: "🚨 EMERGENCY TRIGGERED"
- Shows detected phrase: "help"
- Shows timestamp

**SMS Preview:**
- Updates to emergency format
- Shows: "🚨 EMERGENCY ALERT"

**Pass Criteria:**
- ✅ Keywords detected in voice
- ✅ Console logs show matches
- ✅ Trigger Rule UI updates
- ✅ Emergency banner appears
- ✅ SMS preview updates

---

### ✅ Test 5: Keyword Detection in Manual Text (Step 4)

**Objective:** Verify keywords detected in manual textarea

**Prerequisites:**
- Steps 1 and 2 completed

**Steps:**
1. Scroll to Step 4
2. In textarea, type: "Someone is following me with a knife"
3. Observe console logs (as you type)
4. Check Trigger Rule UI
5. Check emergency banner

**Expected Results:**

**Console Logs:**
```
[TRIGGER] Keyword matched: "following" (source: manual)
[TRIGGER] Keyword matched: "knife" (source: manual)
```

**Trigger Rule UI (Step 4):**
```
🔔 Trigger Rule
Emergency keywords enabled: emergency, help, call 911, call police, help me, scared, following, danger, attack, knife...
Last match: knife at 10:31:20 AM
```

**Emergency Banner:**
- Appears at top of page
- Shows: "🚨 EMERGENCY TRIGGERED"
- Shows detected phrase: "knife"

**SMS Preview:**
- Updates to emergency format
- Shows: "🚨 EMERGENCY ALERT"

**Pass Criteria:**
- ✅ Keywords detected as user types
- ✅ Console logs show matches
- ✅ Trigger Rule UI updates in Step 4
- ✅ Emergency banner appears
- ✅ SMS preview updates

---

### ✅ Test 6: localStorage Persistence

**Objective:** Verify custom keywords persist across page refreshes

**Steps:**
1. Add custom keywords: `knife, weapon, stalker`
2. Verify keywords added (status message)
3. Note the total keyword count
4. Refresh page (F5)
5. Hard refresh (Ctrl+Shift+R)
6. Complete Steps 1 and 2 again
7. Check Trigger Rule UI in Step 3

**Expected Results:**

**After Refresh:**
- Custom keywords still present
- Trigger Rule UI shows: "emergency, help, call 911, help me, scared, following, danger, attack, knife, weapon, stalker..."
- Total keyword count matches before refresh

**Console Logs:**
```
[KEYWORDS] Loaded custom keywords from localStorage: ["knife", "weapon", "stalker"]
```

**Test Keyword Detection:**
- Type "weapon" in Step 4 textarea
- Verify keyword detected: `[TRIGGER] Keyword matched: "weapon" (source: manual)`

**Pass Criteria:**
- ✅ Keywords persist after F5 refresh
- ✅ Keywords persist after hard refresh
- ✅ Keywords still work for detection
- ✅ Console logs confirm localStorage load

---

### ✅ Test 7: Reset to Defaults

**Objective:** Verify Reset to Defaults button works

**Steps:**
1. Add custom keywords: `knife, weapon, stalker`
2. Verify keywords added
3. Click "Reset to Defaults" button
4. Observe status message
5. Check Trigger Rule UI
6. Refresh page
7. Check Trigger Rule UI again

**Expected Results:**

**Status Message:**
```
Reset to default keywords (9 keywords)
```
(Message disappears after 3 seconds)

**Trigger Rule UI:**
```
🔔 Trigger Rule
Emergency keywords enabled: emergency, help, call 911, call police, help me, scared, following, danger, attack
Last match: None
```

**Console Logs:**
```
[KEYWORDS] Cleared custom keywords from localStorage
[KEYWORDS] Reset to defaults: ["emergency", "help", "call 911", "call police", "help me", "scared", "following", "danger", "attack"]
```

**After Refresh:**
- Only default keywords present (9 keywords)
- No custom keywords

**Pass Criteria:**
- ✅ Status message appears
- ✅ Trigger Rule UI shows only defaults
- ✅ Console logs confirm reset
- ✅ localStorage cleared
- ✅ Keywords remain reset after refresh

---

### ✅ Test 8: Enter Key Support

**Objective:** Verify Enter key works in keywords input

**Steps:**
1. Click in the custom keywords input field
2. Type: `knife, weapon`
3. Press **Enter** key (do not click button)
4. Observe status message
5. Check Trigger Rule UI

**Expected Results:**

**Status Message:**
```
Added 2 new keyword(s). Total: 11 keywords.
```

**Trigger Rule UI:**
- Shows new keywords: "knife, weapon"

**Pass Criteria:**
- ✅ Enter key adds keywords (same as clicking button)
- ✅ Status message appears
- ✅ Trigger Rule UI updates

---

### ✅ Test 9: Duplicate Keywords

**Objective:** Verify duplicate keywords are not added

**Steps:**
1. Add keywords: `knife, weapon`
2. Verify added (status: "Added 2 new keyword(s)")
3. Add same keywords again: `knife, weapon`
4. Observe status message

**Expected Results:**

**Status Message:**
```
Added 0 new keyword(s). Total: 11 keywords.
```

**Trigger Rule UI:**
- No duplicate keywords
- Total count unchanged

**Pass Criteria:**
- ✅ Duplicate keywords not added
- ✅ Status message shows 0 added
- ✅ Total count unchanged

---

### ✅ Test 10: Case-Insensitive Matching

**Objective:** Verify keyword matching is case-insensitive

**Test Cases:**

| Input Text | Keyword | Should Match? |
|------------|---------|---------------|
| "HELP ME" | "help me" | ✅ Yes |
| "Help Me" | "help me" | ✅ Yes |
| "help me" | "help me" | ✅ Yes |
| "EMERGENCY" | "emergency" | ✅ Yes |
| "Emergency" | "emergency" | ✅ Yes |
| "Call 911" | "call 911" | ✅ Yes |

**Steps:**
1. For each test case, type the input text in Step 4 textarea
2. Observe console logs
3. Verify keyword detected

**Expected Results:**
- All test cases should match
- Console logs: `[TRIGGER] Keyword matched: "<keyword>" (source: manual)`

**Pass Criteria:**
- ✅ All uppercase matches
- ✅ Mixed case matches
- ✅ All lowercase matches

---

### ✅ Test 11: Phrase Matching

**Objective:** Verify multi-word phrases match correctly

**Test Cases:**

| Input Text | Keyword | Should Match? |
|------------|---------|---------------|
| "Please call 911 now" | "call 911" | ✅ Yes |
| "I need help me please" | "help me" | ✅ Yes |
| "Stop following me" | "following me" | ✅ Yes |
| "Someone is following me" | "following" | ✅ Yes |
| "call911" (no space) | "call 911" | ❌ No |

**Steps:**
1. For each test case, type the input text in Step 4 textarea
2. Observe console logs
3. Verify keyword detected or not detected

**Expected Results:**
- Phrases with spaces match correctly
- Single words match with word boundaries
- No false positives

**Pass Criteria:**
- ✅ Multi-word phrases match
- ✅ Single words match with word boundaries
- ✅ No false positives

---

### ✅ Test 12: Empty Input Handling

**Objective:** Verify empty input is handled gracefully

**Steps:**
1. Click in keywords input field
2. Leave it empty
3. Click "Add Keywords" button
4. Observe status message

**Expected Results:**

**Status Message:**
```
Please enter keywords
```
(Red color, error style)

**Pass Criteria:**
- ✅ Error message appears
- ✅ No keywords added
- ✅ No console errors

---

### ✅ Test 13: Special Characters

**Objective:** Verify special characters are handled

**Test Cases:**

| Input | Expected Result |
|-------|----------------|
| `knife, weapon!` | Keywords: "knife", "weapon!" |
| `help!, danger?` | Keywords: "help!", "danger?" |
| `@emergency, #help` | Keywords: "@emergency", "#help" |

**Steps:**
1. Enter keywords with special characters
2. Click "Add Keywords"
3. Verify keywords added
4. Test detection by typing in Step 4 textarea

**Expected Results:**
- Keywords added with special characters
- Detection works with special characters

**Pass Criteria:**
- ✅ Special characters preserved
- ✅ Detection works correctly

---

### ✅ Test 14: SMS Preview Integration

**Objective:** Verify SMS preview updates when keywords detected

**Steps:**
1. Complete Steps 1 and 2
2. Scroll to Step 5 SMS Preview
3. Observe initial state (standby)
4. Type "help" in Step 4 textarea
5. Observe SMS preview update

**Expected Results:**

**Before Keyword:**
```
Standby: no emergency trigger detected yet.
```

**After Keyword:**
```
🚨 EMERGENCY ALERT

Risk: [threat analysis]
Recommendation: [recommendation]

Timestamp: [time]
Location: [coordinates]
Google Maps: [link]

Message: "help"
```

**Pass Criteria:**
- ✅ SMS preview starts in standby
- ✅ SMS preview updates to emergency format after keyword
- ✅ Emergency alert format includes all required fields

---

## Regression Tests

### ✅ Regression 1: Step 2 Location Still Works

**Objective:** Verify Step 1 fix didn't break Step 2

**Steps:**
1. Complete Step 1
2. Click "Enable Location" in Step 2
3. Grant location permission
4. Verify location captured

**Pass Criteria:**
- ✅ Step 2 location capture works
- ✅ Selected Location panel appears
- ✅ Google Maps link works

---

### ✅ Regression 2: Step 3 Voice Detection Still Works

**Objective:** Verify keywords field didn't break voice detection

**Steps:**
1. Complete Steps 1 and 2
2. Click "Start Voice Detection"
3. Grant microphone permission
4. Say something (not a keyword)
5. Verify transcript appears

**Pass Criteria:**
- ✅ Voice detection starts
- ✅ Transcript appears in real-time
- ✅ No console errors

---

### ✅ Regression 3: Step 4 Threat Analysis Still Works

**Objective:** Verify keywords field didn't break threat analysis

**Steps:**
1. Complete Steps 1 and 2
2. Type text in Step 4 textarea (not a keyword)
3. Click "Analyze with Gemini3"
4. Verify threat analysis runs

**Pass Criteria:**
- ✅ Threat analysis runs
- ✅ Results appear
- ✅ No console errors

---

## Browser Compatibility

Test in multiple browsers:

- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Edge (latest)
- [ ] Safari (latest)
- [ ] Mobile Chrome (Android)
- [ ] Mobile Safari (iOS)

---

## Performance Tests

### ✅ Performance 1: Keyword Detection Speed

**Objective:** Verify keyword detection is fast

**Steps:**
1. Add 20 custom keywords
2. Type in Step 4 textarea
3. Observe detection speed

**Expected Results:**
- Detection happens instantly (< 100ms)
- No lag or delay
- No performance degradation

**Pass Criteria:**
- ✅ Detection is instant
- ✅ No UI lag

---

### ✅ Performance 2: localStorage Size

**Objective:** Verify localStorage doesn't grow too large

**Steps:**
1. Add 50 custom keywords
2. Check localStorage size in browser DevTools
3. Verify reasonable size

**Expected Results:**
- localStorage size < 10KB
- No performance impact

**Pass Criteria:**
- ✅ localStorage size reasonable
- ✅ No performance impact

---

## Security Tests

### ✅ Security 1: XSS Prevention

**Objective:** Verify no XSS vulnerabilities

**Test Cases:**

| Input | Expected Result |
|-------|----------------|
| `<script>alert('xss')</script>` | Treated as text, no script execution |
| `<img src=x onerror=alert('xss')>` | Treated as text, no script execution |

**Steps:**
1. Enter XSS payloads as keywords
2. Verify no script execution
3. Verify keywords treated as text

**Pass Criteria:**
- ✅ No script execution
- ✅ XSS payloads treated as text

---

## Test Summary Template

```
Test Date: [date]
Tester: [name]
Build: GEMINI3-STEP1-KEYWORDS-FIX-20260128
Browser: [browser name and version]

Test Results:
[ ] Test 1: Step 1 Button Click Progression
[ ] Test 2: Step 1 E.164 Phone Validation
[ ] Test 3: Add Custom Keywords
[ ] Test 4: Keyword Detection in Voice
[ ] Test 5: Keyword Detection in Manual Text
[ ] Test 6: localStorage Persistence
[ ] Test 7: Reset to Defaults
[ ] Test 8: Enter Key Support
[ ] Test 9: Duplicate Keywords
[ ] Test 10: Case-Insensitive Matching
[ ] Test 11: Phrase Matching
[ ] Test 12: Empty Input Handling
[ ] Test 13: Special Characters
[ ] Test 14: SMS Preview Integration

Regression Tests:
[ ] Regression 1: Step 2 Location Still Works
[ ] Regression 2: Step 3 Voice Detection Still Works
[ ] Regression 3: Step 4 Threat Analysis Still Works

Issues Found:
[list any issues]

Notes:
[any additional notes]
```

---

## Quick Smoke Test (5 minutes)

For quick verification:

1. ✅ Open app, verify build stamp
2. ✅ Complete Step 1, verify button works
3. ✅ Add custom keyword: `knife`
4. ✅ Type "knife" in Step 4, verify detected
5. ✅ Refresh page, verify keyword persists
6. ✅ Click Reset to Defaults, verify reset

If all pass, deployment is successful.
