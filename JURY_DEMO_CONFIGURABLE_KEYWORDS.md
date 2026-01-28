# Jury Demo Quick Reference - Configurable Keywords

**Build**: GEMINI3-CONFIGURABLE-KEYWORDS-20260127  
**URL**: https://d3pbubsw4or36l.cloudfront.net  
**Time**: 5 minutes  
**Browser**: Chrome or Edge (recommended)

---

## Pre-Demo Checklist (30 seconds)

- [ ] Open URL in Chrome/Edge
- [ ] Verify build stamp shows: GEMINI3-CONFIGURABLE-KEYWORDS-20260127
- [ ] Close any other tabs (reduce noise)
- [ ] Ensure microphone works (test in browser settings)
- [ ] Have backup plan ready (Demo Location, manual keywords)

---

## Demo Script (5 minutes)

### 1. Introduction (30 seconds)

**Say**: "This is the AllSensesAI Gemini3 Guardian emergency detection system with configurable emergency keywords, achieving functional parity with the ERNIE system."

**Show**: Header with "Gemini3 Guardian" and build stamp

---

### 2. Steps 1-2: Quick Setup (1 minute)

**Step 1**:
- Enter: "Demo User"
- Enter: "+1234567890"
- Click: "Complete Step 1"

**Step 2**:
- Click: "Use Demo Location" (instant, reliable)
- **Point out**: Selected Location Panel appears
- **Point out**: Google Maps link (opens in new tab)
- **Say**: "Location captured and ready for emergency response"

---

### 3. Keyword Configuration (1 minute 30 seconds)

**Point out**: Yellow "Emergency Keywords Configuration" panel in Step 3

**Say**: "The system comes with default keywords like 'emergency', 'help', 'call police', 'scared', 'following', 'danger', and 'attack'."

**Demo custom keyword**:
- Type in input field: "banana911"
- Click: "Add Keyword" (or press Enter)
- **Point out**: New keyword chip appears
- **Say**: "Keywords are stored in localStorage and persist across page reloads"

**Optional**: Remove a keyword by clicking the × button to show flexibility

---

### 4. Emergency Detection (2 minutes)

**Start voice detection**:
- Click: "Start Voice Detection"
- **Point out**: Badge changes to "🎤 Listening"
- **Point out**: Live transcript box appears

**Trigger emergency**:
- **Say clearly**: "banana911" (or "emergency")
- **Watch for** (happens in < 1 second):
  1. Badge flips to "🚨 EMERGENCY DETECTED" (red, pulsing)
  2. Red emergency banner appears at top
  3. Emergency modal pops up (auto-closes after 2 seconds)
  4. Proof log shows [TRIGGER] entry
  5. Step 4 auto-populates with transcript

**Point out key details**:
- **Banner shows**: Timestamp, detected phrase, location, coordinates
- **Google Maps link**: Click to verify exact location
- **Proof log**: Shows complete audit trail
- **Auto-escalation**: System automatically advances to threat analysis

**Say**: "Emergency detected in under 1 second, with complete evidence capture including transcript and live location."

---

### 5. Reset Demo (30 seconds)

**Show reset functionality**:
- Click: "Reset Emergency State" button
- **Point out**:
  - Emergency banner disappears
  - Badge returns to normal
  - Pipeline state resets to idle
  - Proof log shows [RESET] entry

**Say**: "Reset allows multiple demo runs without page reload, perfect for demonstrations."

---

### 6. Persistence & Zero ERNIE (30 seconds)

**Show persistence**:
- Hard refresh page (Ctrl+Shift+R or Cmd+Shift+R)
- **Point out**: Custom keyword "banana911" still present
- **Say**: "Keywords persist via localStorage"

**Verify zero ERNIE**:
- Press Ctrl+F (or Cmd+F)
- Search: "ERNIE"
- **Point out**: 0 matches found
- **Say**: "Zero ERNIE exposure, 100% Gemini3 branding"

---

## Key Talking Points

### Feature Highlights
1. **Configurable Keywords**: Users can add/remove emergency trigger words
2. **localStorage Persistence**: Keywords survive page reloads
3. **Sub-Second Detection**: Emergency detected in < 1 second
4. **Complete Evidence**: Transcript + location locked at trigger time
5. **Auto-Escalation**: Automatic progression to threat analysis and alerting
6. **Reset Capability**: Multiple demo runs without page reload
7. **ERNIE Parity**: Functional equivalence with ERNIE system
8. **Zero ERNIE Exposure**: 100% Gemini3 branding

### Technical Highlights
1. **3 New Classes**: EmergencyKeywordsConfig, KeywordDetectionEngine, EmergencyStateManager
2. **Smart Matching**: Word boundary for single words, substring for phrases
3. **Additive Only**: Zero regressions, all existing features preserved
4. **Self-Explanatory UI**: Clear labels, help text, examples
5. **Error Handling**: Validation, fallbacks, user feedback

---

## Backup Plans

### If Microphone Doesn't Work
1. **Say**: "For demo purposes, I'll manually type the keyword"
2. Skip voice detection
3. Manually type "emergency" in Step 4 textarea
4. Continue with threat analysis
5. **Point out**: Keyword configuration still works, just not voice detection

### If GPS Fails
1. Already using Demo Location (recommended)
2. **Say**: "Using demo location for reliable demonstration"
3. Show location panel with coordinates
4. Click Google Maps link to verify

### If Browser Issues
1. Switch to Chrome or Edge
2. **Say**: "Web Speech API works best in Chrome/Edge"
3. Continue demo

---

## Success Criteria

### Must Show
- [x] Keyword configuration UI visible
- [x] Custom keyword added successfully
- [x] Emergency detected in < 1 second
- [x] Badge changes to EMERGENCY DETECTED
- [x] Red emergency banner appears
- [x] Proof log shows trigger
- [x] Reset button clears state
- [x] Keywords persist after refresh
- [x] Zero ERNIE references

### Nice to Show
- [ ] Remove keyword functionality
- [ ] Google Maps link opens
- [ ] Auto-advance to Step 4
- [ ] Gemini3 threat analysis
- [ ] Emergency alert sent

---

## Common Questions & Answers

**Q**: How many keywords can be configured?  
**A**: Unlimited. System uses O(n) matching with early exit optimization.

**Q**: Do keywords work with voice and text?  
**A**: Yes. Voice transcripts are checked in real-time, and text can be manually entered.

**Q**: What happens if localStorage is disabled?  
**A**: Falls back to in-memory storage. Keywords work during session but don't persist.

**Q**: Can keywords be phrases?  
**A**: Yes. Single words use word boundary matching, multi-word phrases use substring matching.

**Q**: How fast is detection?  
**A**: < 1 second from keyword spoken to emergency triggered.

**Q**: Does this replace ERNIE?  
**A**: No, this is Gemini3. It achieves functional parity with ERNIE's keyword detection.

**Q**: Are there any ERNIE references?  
**A**: Zero. Confirmed via automated scan. 100% Gemini3 branding.

---

## Troubleshooting

### Emergency Not Triggering
1. Check microphone permission granted
2. Verify keyword in list (check spelling)
3. Speak clearly and wait 1-2 seconds
4. Check proof log for transcript
5. Try default keyword like "emergency"

### Keywords Not Persisting
1. Check localStorage enabled in browser
2. Check browser privacy settings
3. Try incognito mode (localStorage works there too)
4. Verify no browser extensions blocking storage

### Badge Not Updating
1. Hard refresh page (Ctrl+Shift+R)
2. Clear browser cache
3. Check browser console for errors
4. Verify build stamp is correct

---

## Post-Demo Notes

### Feedback to Gather
- [ ] Was keyword configuration UI clear?
- [ ] Was detection speed acceptable?
- [ ] Was reset functionality useful?
- [ ] Were default keywords appropriate?
- [ ] Any suggested improvements?

### Metrics to Track
- [ ] Time to emergency detection
- [ ] Number of false positives
- [ ] User satisfaction with UI
- [ ] Keyword configuration usage
- [ ] Reset button usage

---

## Quick Commands

### Open URL
```
https://d3pbubsw4or36l.cloudfront.net
```

### Search for ERNIE
```
Ctrl+F → "ERNIE" → 0 matches
```

### Hard Refresh
```
Ctrl+Shift+R (Windows/Linux)
Cmd+Shift+R (Mac)
```

### Open Browser Console
```
F12 or Ctrl+Shift+I
```

---

## Final Checklist

### Before Demo
- [ ] URL accessible
- [ ] Build stamp verified
- [ ] Microphone tested
- [ ] Demo script reviewed
- [ ] Backup plans ready

### During Demo
- [ ] Introduction clear
- [ ] Steps 1-2 completed
- [ ] Keyword configuration shown
- [ ] Emergency detection demonstrated
- [ ] Reset functionality shown
- [ ] Zero ERNIE confirmed

### After Demo
- [ ] Feedback gathered
- [ ] Questions answered
- [ ] Next steps discussed
- [ ] Documentation provided

---

**🚀 READY FOR JURY DEMONSTRATION 🚀**

**Good luck!**
