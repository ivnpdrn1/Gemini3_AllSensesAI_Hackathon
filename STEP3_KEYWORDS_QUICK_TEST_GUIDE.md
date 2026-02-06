# Step 3 Keywords UI - Quick Test Guide

## How to Test the Implementation

### 1. Open the Application

Open `gemini3-guardian-production-sms-FINAL.html` in your browser.

### 2. Navigate to Step 3

Scroll down to the **Step 3 — Voice Emergency Detection** section.

### 3. Verify Initial Display

You should see:
- ✅ **Emergency Keywords Configuration** heading with a counter (e.g., "Keywords: 7")
- ✅ A list of default keywords displayed as chips (e.g., "emergency", "help", "call police", etc.)
- ✅ Each keyword chip has an × button to remove it
- ✅ An input field with placeholder text
- ✅ A green "➕ Add Keyword" button
- ✅ Helper text with examples and note about Step 4

### 4. Test Adding Keywords

**Test 4a: Add Valid Keyword**
1. Type "socorro" in the input field
2. Click the "Add Keyword" button (or press Enter)
3. ✅ Verify the keyword appears as a new chip
4. ✅ Verify the counter increments (e.g., "Keywords: 8")
5. ✅ Verify the input field clears

**Test 4b: Try to Add Empty Keyword**
1. Leave the input field empty
2. Click the "Add Keyword" button
3. ✅ Verify nothing happens (no alert, no new chip)

**Test 4c: Try to Add Duplicate Keyword**
1. Type "emergency" (a keyword that already exists)
2. Click the "Add Keyword" button
3. ✅ Verify an alert appears: "This keyword already exists"
4. ✅ Verify no duplicate chip is added

**Test 4d: Test Enter Key**
1. Type "auxilio" in the input field
2. Press the Enter key
3. ✅ Verify the keyword is added (same as clicking the button)

### 5. Test Removing Keywords

**Test 5a: Remove a Keyword**
1. Click the × button on any keyword chip (except the last one)
2. ✅ Verify the chip disappears
3. ✅ Verify the counter decrements

**Test 5b: Try to Remove Last Keyword**
1. Remove keywords until only one remains
2. Try to click the × button on the last keyword
3. ✅ Verify an alert appears: "You must have at least one emergency keyword configured"
4. ✅ Verify the last keyword remains

### 6. Test Persistence

**Test 6a: Reload Page**
1. Add a custom keyword (e.g., "danger zone")
2. Reload the page (F5 or Ctrl+R)
3. ✅ Verify the custom keyword is still there
4. ✅ Verify the counter shows the correct count

**Test 6b: Close and Reopen Browser**
1. Add a custom keyword
2. Close the browser completely
3. Reopen the browser and load the page
4. ✅ Verify the custom keyword persists

### 7. Test Emergency Detection Integration

**Test 7a: Complete Steps 1 & 2**
1. Fill in Step 1 (name and phone number)
2. Click "Complete Step 1"
3. Enable location in Step 2 (or use demo location)

**Test 7b: Test Voice Detection with Custom Keyword**
1. Add a custom keyword (e.g., "test emergency")
2. Click "Start Voice Detection" in Step 3
3. Speak the custom keyword clearly
4. ✅ Verify the emergency workflow triggers
5. ✅ Verify the emergency banner appears
6. ✅ Verify the emergency modal shows

**Test 7c: Test with Default Keyword**
1. Speak a default keyword (e.g., "help")
2. ✅ Verify the emergency workflow triggers

### 8. Test Non-Regression

**Test 8a: Step 1 Still Works**
1. Verify Step 1 input fields work
2. Verify Step 1 validation works
3. Verify Step 1 completion works

**Test 8b: Step 2 Still Works**
1. Verify location enable button works
2. Verify demo location button works
3. Verify location display updates

### 9. Browser Console Verification

Open the browser console (F12) and verify:
- ✅ `[KEYWORDS] Loaded from localStorage:` message appears on page load
- ✅ `[KEYWORDS] Added:` message appears when adding keywords
- ✅ `[KEYWORDS] Removed:` message appears when removing keywords
- ✅ `[KEYWORDS] Current keywords:` shows the updated list

### 10. Visual Verification

Check that the UI looks correct:
- ✅ Keywords are displayed as rounded chips
- ✅ Chips have a yellow/amber border
- ✅ Remove buttons (×) are visible and red
- ✅ Input field is properly styled
- ✅ Add button is green
- ✅ Helper text is visible and readable
- ✅ Counter is visible next to the heading

## Expected Behavior Summary

| Action | Expected Result |
|--------|----------------|
| Page load | Default keywords displayed, counter shows count |
| Add valid keyword | Keyword appears, counter increments, input clears |
| Add empty keyword | Nothing happens, no error |
| Add duplicate keyword | Alert shown, keyword not added |
| Press Enter in input | Same as clicking Add button |
| Remove keyword | Keyword disappears, counter decrements |
| Remove last keyword | Alert shown, keyword remains |
| Reload page | Custom keywords persist |
| Speak custom keyword | Emergency workflow triggers |
| Speak default keyword | Emergency workflow triggers |

## Troubleshooting

### Keywords Don't Persist After Reload
- Check if localStorage is enabled in your browser
- Check browser console for localStorage errors
- Try in a non-private/incognito window

### Emergency Detection Doesn't Work
- Verify microphone permissions are granted
- Verify Steps 1 and 2 are completed
- Check browser console for detection logs
- Speak clearly and wait for transcription

### UI Doesn't Update
- Check browser console for JavaScript errors
- Verify the HTML file is the latest version
- Try a hard refresh (Ctrl+Shift+R)

## Success Criteria

All tests pass if:
- ✅ Keywords display correctly
- ✅ Counter shows accurate count
- ✅ Adding keywords works with validation
- ✅ Removing keywords works with protection
- ✅ Keywords persist across sessions
- ✅ Emergency detection works with custom keywords
- ✅ Steps 1 and 2 remain unchanged
- ✅ No JavaScript errors in console

**Status**: Ready for testing!
