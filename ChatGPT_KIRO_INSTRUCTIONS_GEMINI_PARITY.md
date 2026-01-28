KIRO Instruction — Add VISION Mode (Gemini Vision) to AllSensesAI
Objective

Add Visual Context Analysis (Gemini Vision) as an automatic, safety-triggered capability to AllSensesAI.
The feature must activate only when risk is detected and must explain itself entirely through the UI, for both users in danger and jury observers.

No additional explanation should be required.
The product must communicate intent, scope, and safety on its own.

Guiding Principles (Non-Negotiable)

Vision is corroboration, not primary input

Vision is never manually activated

Vision never replaces audio or keyword triggers

Safety over spectacle

Capture minimal visual evidence

Analyze context, not identities

Explainability over raw output

No raw Gemini text dumps

Structured findings only

User = Jury

Treat both as the same first-time viewer

Everything must be obvious on screen

Where VISION Fits in the Pipeline

Keep the existing 5-step flow:

Config

Location

Voice

Analysis (Enhanced with Vision)

Alert

VISION is a sub-stage of Step 4.
Do not add a new step.

Trigger Conditions (Automatic Only)

VISION activates when ANY of the following occur:

Emergency keyword detected

Suspicious noise pattern detected (panic, scream, struggle)

Emergency state flag is set

No buttons. No toggles. No user decisions.

Step 4 — Threat Analysis (UI Changes Required)

Add a new panel:

🔍 Visual Context Analysis (Gemini Vision)

Status flow (visible):

Waiting for trigger

Capturing visual context

Analyzing environment

Analysis complete

What the system does (must be visible in text):

Captures 1–3 still frames

Uses front camera first, rear as fallback

Only during active emergency

No continuous recording

Gemini Vision Analysis Scope (Must Be Explicit in UI)

Show a short label such as:

“Analyzing environment for safety risk indicators”

Gemini must analyze for:

Presence of other people

Signs of physical threat or coercion

Confined or isolated environments

Vehicles or enclosed spaces

Low-light or obstructed visibility

Aggressive posture or proximity

Objects that may indicate danger (non-sensational)

Prompting Rules (For KIRO Implementation)

Gemini Vision prompts must be safety-scoped.

Example instruction (conceptual, not shown to user):

“Analyze this image for indicators of personal danger or distress.
Identify environmental risk factors only.
Do not identify individuals.
Respond with a structured safety assessment.”

Visual Output (Strictly Structured)

The UI must display:

Thumbnail(s) (blurred by default)

Structured findings, e.g.:

“Multiple individuals detected nearby”

“Confined indoor environment”

“Low visibility conditions”

Confidence level: Low / Medium / High

❌ No free-form Gemini paragraphs
❌ No emotional or speculative language

Evidence Packet Expansion (Critical)

When Vision is triggered, the emergency packet must visibly include:

🎙️ Trigger transcript snippet

📍 Live location (with Google Maps link)

🖼️ Visual context findings

🧠 Combined risk assessment (audio + vision)

Display a label:

“Evidence captured to assist responders”

Privacy & Trust Signals (Must Be Visible)

Without explanation text blocks, include small UI cues:

“Images captured only during emergency”

“No continuous recording”

“Secure analysis”

This reassures both user and jury instantly.

Reset Behavior (Demo & Safety)

“Reset Emergency State” must:

Clear visual findings

Clear captured frames

Return Vision panel to idle state

Vision must not activate again until a new trigger

Acceptance Criteria (What Will Be Verified)

Say emergency keyword → Step 4 auto-shows Vision panel

Visual analysis runs without user input

Findings are understandable in <5 seconds

Jury can explain what Vision does by only reading the screen

Reset clears everything cleanly

No regressions to existing workflow

Naming (Use Consistently)

Use one of the following everywhere:

Visual Context Analysis

Environmental Risk Scan

Avoid:

“Camera Mode”

“Image Capture”

“Vision Mode” (too technical)

Definition of Done

A first-time viewer can clearly understand:

why images were captured,

what was analyzed,

how it helps the person in danger,

and how it strengthens emergency response,

without anyone explaining it verbally.