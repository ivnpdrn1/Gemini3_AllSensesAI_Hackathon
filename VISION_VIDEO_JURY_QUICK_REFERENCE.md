# Vision/Video Feature - Jury Quick Reference

**Build:** GEMINI3-VISION-VIDEO-FIX-20260127  
**Feature:** Visual Context Analysis with Video Frames

## What to Show the Jury

### 1. BEFORE Emergency (Standby State)

**Location:** Step 4 — Gemini3 Threat Analysis

**What's Visible:**
- 🎥 **Panel Title:** "Visual Context (Gemini Vision) — Video Frames"
- **Status Badge:** "Standby" (grey)
- **Explainer Text:** 
  - "Standby: activates automatically during detected risk"
  - "Capture policy: Captures 1–3 video frames during emergency. No continuous recording."
- **Video Frames Section:** "📹 Video Frames (Standby)"
  - Frame 1 — not captured (grey box)
  - Frame 2 — not captured (grey box)
  - Frame 3 — not captured (grey box)
- **Placeholders:**
  - Findings: —
  - Confidence: —
  - Vision/Video Status: Standby

**Key Point:** The panel is ALWAYS VISIBLE, even before any emergency. This proves the feature exists.

### 2. DURING Emergency (Activation State)

**Trigger:** Click "Analyze with Gemini" button

**What Changes (< 1 second):**
- **Status Badge:** Changes to "Capturing…" (yellow, pulsing)
- **Trigger Reason Appears:** "Activated because: Emergency trigger detected ('emergency')"
- **Progress Indicators Show:**
  - ✅ Trigger received
  - ⏳ Capturing frames
  - ⏳ Analyzing environment
  - ⏳ Publishing findings
- **Placeholders Update:** "Vision/Video Status: Capturing frames…"

**Key Point:** The transition is immediate and self-explanatory. No verbal explanation needed.

### 3. AFTER Emergency (Completed State)

**What's Visible:**
- **Status Badge:** "Complete" (green)
- **Video Frames:** 2 demo thumbnails (blurred by default)
  - "Tap to view" button to unblur
- **Findings List:**
  - Multiple individuals detected nearby
  - Isolated location detected
  - (Findings vary based on transcript content)
- **Confidence Badge:** Low / Medium / High (color-coded)
- **Evidence Indicator:** "✅ Added to Evidence Packet"
- **Vision/Video Status:** "Findings recorded (2 frames, confidence: medium)"

**Key Point:** All results are structured and easy to understand. No technical jargon.

### 4. RESET (Return to Standby)

**Action:** Refresh the page

**What Happens:**
- Panel returns to Standby state
- All placeholders restored
- Video frames show "not captured" again
- Status badge shows "Standby"

**Key Point:** Clean reset proves the state machine works correctly.

## Jury Demonstration Script

### Opening Statement
"The Vision/Video feature is always visible in Step 4, even before any emergency occurs. Let me show you the three states."

### Step 1: Show Standby
"Here in Step 4, you can see the Visual Context panel. Notice the 'Video Frames (Standby)' section with three grey placeholders. This proves the feature exists and is ready, but hasn't captured anything yet."

### Step 2: Trigger Emergency
"Now I'll click 'Analyze with Gemini' to simulate an emergency. Watch the panel..."

### Step 3: Show Activation
"See how it immediately changes to 'Capturing' and shows progress indicators? The trigger reason is displayed: 'Emergency trigger detected'. This happens in less than a second."

### Step 4: Show Completion
"Now it's complete. You can see two video frames (blurred for privacy), structured findings about the environment, and a confidence level. Everything is added to the evidence packet that would be sent to emergency responders."

### Step 5: Show Unblur
"If needed, responders can click 'Tap to view' to see the actual frames. But by default, they're blurred for privacy."

### Step 6: Show Reset
"If I refresh the page, everything returns to Standby state, ready for the next emergency."

## Key Talking Points

1. **Always Visible:** The panel is never hidden. It's always in Step 4, showing current state.

2. **Self-Explanatory:** Every state has clear labels and explanations. No verbal explanation needed.

3. **Video/Frames Language:** Explicitly uses "Video Frames" terminology throughout, making it clear this is visual evidence.

4. **Before/After Proof:** The placeholders before trigger and actual frames after trigger provide clear before/after evidence.

5. **Privacy-First:** Frames are blurred by default. Only 1-3 still frames, no continuous recording.

6. **Non-Blocking:** Vision analysis runs in parallel with threat analysis. System continues even if vision fails.

7. **Demo Mode:** Current implementation uses simulated frames, making it hardware-independent and reliable for demonstrations.

## Common Questions & Answers

**Q: Why are the frames blurred?**  
A: Privacy protection. Responders can unblur if needed, but default is blurred.

**Q: Does this record video continuously?**  
A: No. Only 1-3 still frames during emergency. No continuous recording.

**Q: What if the camera isn't available?**  
A: System continues with audio and location only. Vision is supplementary, not required.

**Q: How do responders know what was detected?**  
A: Structured findings list (e.g., "Multiple individuals detected nearby") with confidence level.

**Q: Can users disable this?**  
A: Yes, in production. Demo mode is always enabled for reliable demonstrations.

**Q: What happens if I reset?**  
A: Everything returns to Standby state. Panel shows placeholders again, ready for next emergency.

## Technical Notes (If Asked)

- **State Machine:** standby → capturing → analyzing → complete
- **Demo Mode:** Uses simulated frames (no camera required)
- **Integration:** Triggers automatically when "Analyze with Gemini" is clicked
- **Evidence Packet:** Vision status tracked throughout: "Standby" → "Capturing frames…" → "Findings recorded (N frames, confidence: X)"
- **Build:** GEMINI3-VISION-VIDEO-FIX-20260127

## Verification Checklist

Before demonstrating to jury, verify:

- [ ] Panel visible in Step 4 immediately on page load
- [ ] "Video Frames (Standby)" section visible with 3 grey boxes
- [ ] Standby badge and explainer text visible
- [ ] Click "Analyze with Gemini" triggers activation
- [ ] Status changes to "Capturing…" then "Analyzing…" then "Complete"
- [ ] Thumbnails appear (blurred)
- [ ] Findings list appears with bullets
- [ ] Confidence badge appears (color-coded)
- [ ] "Added to Evidence Packet" indicator appears
- [ ] "Tap to view" button unblurs thumbnails
- [ ] Refresh returns to Standby state

---

**Ready for Jury:** ✅ YES  
**Self-Explanatory:** ✅ YES  
**Hardware Independent:** ✅ YES (Demo Mode)
