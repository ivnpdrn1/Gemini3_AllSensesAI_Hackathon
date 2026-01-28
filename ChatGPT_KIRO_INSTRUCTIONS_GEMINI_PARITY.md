AllSensesAI Gemini3 Guardian — KIRO Instruction Log (Parity + Jury-Ready Baseline)
Purpose of this document

This file preserves the exact instruction logic and reasoning sequence used to reach the current working, jury-ready production state of the AllSensesAI Gemini3 Guardian, and defines the next build objective while protecting the existing baseline.

This is a product parity and jury-proof effort:

Keep the end-to-end 5-step workflow stable.

Preserve proof visibility and determinism.

Extend capability without regressions.

Current Verified Baseline (DO NOT BREAK)
Production URL (current working)

CloudFront: https://dfc8ght8abwqc.cloudfront.net/

Build Identity Proof (must remain visible)

Build ID displayed in two places:

Top build stamp near header

Runtime Health Check panel (“Loaded Build ID”)

Current observed Build ID:

GEMINI3-JURY-READY-20260128-v1

This dual-display build identity is mandatory for jury verification.

What is confirmed working (baseline acceptance)
Step 1 — Configuration (working)

Name field + E.164 phone field

“Complete Step 1” works (no dead button)

E.164 validation enforced (must keep)

Saves configuration and unlocks Step 2

Step 2 — Location Services (working)

Real GPS capture + displayed “Selected Location”

Proof log shows location events and Google Maps link

Demo location option exists

Step 3 — Voice Emergency Detection (working)

Microphone listening state + live transcript + proof log

Configurable emergency keywords UI (chips + add/remove) persists (localStorage)

Trigger detection drives emergency workflow

Step 4 — Gemini Threat Analysis (working)

Analysis button produces threat/risk outputs

Pipeline state progresses to STEP4_COMPLETE

Output supports Step 5 preview

Step 5 — Emergency Alerting (working + complete UI)

Always-visible SMS Preview panel with structured fields:

Victim

Risk

Recommendation

Message

Location

Map

Time

Action

Includes “SMS Text Preview” block

Preview updates deterministically based on current state

Victim name (owner of phone / user) is explicitly shown

Key guarantee: preview matches what would be sent.

Non-goals and boundaries (KIRO must comply)

Do not provide Git instructions.

Do not request repository actions.

Do not change bucket/distribution unless explicitly instructed.

Do not remove working proof logs or jury-visible panels.

Do not degrade the 5-step UX parity.

I (Ivan) will handle repository commits/tags.

How we got here (high-level sequence)

Implemented E.164 parity for international SMS destinations.

Added Step 5 “SMS Preview” concept, but had early builds where functions were missing or Step 1 broke.

Iterated until the app had:

Step 1 reliable click behavior

deterministic SMS composition

Step 5 structured preview always visible

configurable emergency keywords UI

jury-proof Build ID visibility (header + runtime panel)

Deployed the final working baseline to CloudFront:

dfc8ght8abwqc.cloudfront.net

Current Gap (Next Feature)
Missing feature vs prior version: VIDEO / VISION panel

AllSensesAI is “all senses”, and the prior version demonstrated a Visual Context (Gemini Vision) — Video Frames panel.

That panel is not present in the current jury-ready build.

We must re-introduce the VIDEO feature without changing or breaking anything that currently works.