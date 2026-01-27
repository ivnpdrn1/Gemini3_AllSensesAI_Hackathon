# KIRO Instruction Log — ERNIE → GEMINI Product Parity

## Context

The ERNIE Guardian app established the canonical reference architecture,
UI flow, and jury-facing narrative for AllSensesAI.

The GEMINI project must **mirror ERNIE exactly** in product structure,
user experience, and deployment pattern, while replacing ONLY the
AI analysis engine (ERNIE → Google Gemini).

This document captures the instruction logic and reasoning sequence
used when directing KIRO, preserved for future reference.

---

## Guiding Principle

> **GEMINI should wear ERNIE’s clothes.**

This is a **product parity task**, not an infrastructure experiment.

---

## What Worked (ERNIE Reference)

The ERNIE app successfully delivered:

- Clear “AllSensesAI Guardian” positioning
- Step-by-step emergency workflow
- Runtime console introspection (“proof of execution”)
- Architecture transparency (S3, CloudFront, Lambda, DynamoDB, SMS)
- A single, canonical CloudFront HTTPS URL suitable for jury review

This pattern is the baseline.

---

## What NOT to Do

KIRO must avoid:

- Re-inventing UI or flow for GEMINI
- Creating multiple CloudFront distributions
- Over-engineering backend infrastructure
- Treating deployment as the primary goal before product parity
- Printing placeholder or unverifiable URLs

---

## Correct Task Definition (Product Parity)

The GEMINI project must:

1. **Duplicate the ERNIE Guardian frontend**
   - Same layout
   - Same step ordering
   - Same visual hierarchy
   - Same runtime proof panels

2. **Replace ERNIE references with GEMINI**
   - Text labels
   - Model naming
   - Threat analysis section title

3. **Swap ONLY the analysis engine**
   - ERNIE threat analysis → Gemini threat analysis
   - Client-side demo logic is acceptable for jury purposes

4. **Preserve all other functionality**
   - Location services step
   - Voice/text capture step
   - Emergency alert UX
   - SMS preview
   - System status checks
   - Console health/runtime introspection

---

## Deployment Strategy (Deferred Until Parity)

Deployment must only occur **after** UI and flow parity is confirmed.

When deploying:

- Use the **same pattern as ERNIE**
  - S3 + CloudFront
  - Single distribution
  - One canonical HTTPS URL

- Stop immediately after a valid CloudFront domain is produced
- Do not retry, loop, or create parallel resources

---

## Acceptance Criteria

GEMINI Guardian is considered complete when:

- A user cannot visually distinguish it from ERNIE Guardian
- The only semantic difference is the AI engine used
- The app tells the same story to judges
- One stable HTTPS URL exists for submission

---

## Why This Matters

Preserving parity ensures:

- Consistent jury interpretation
- Comparable evaluation across AI engines
- Clear narrative of product evolution (ERNIE → GEMINI)
- Reduced deployment risk
- Stronger architectural credibility

---

## Summary Instruction to KIRO (Canonical)

> Create a GEMINI version that mirrors ERNIE Guardian 1:1 in UI, flow,
> and structure. Replace only the threat analysis engine.
> Do not deploy until parity is confirmed.
