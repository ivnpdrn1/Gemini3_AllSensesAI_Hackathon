ChatGPT–KIRO Instructions
GEMINI Parity, Logic Preservation & System State Reference
1. Purpose of This Document

This document exists to preserve the reasoning sequence that led to the current, stable, jury-ready state of the GEMINI Guardian system.

It is not a task list.
It is not a deployment guide.
It is a logic anchor.

Future changes must be evaluated against this document to ensure:

parity is preserved

history is respected

no accidental regressions are introduced

2. Scope Definition (Non-Negotiable)
Responsibilities

KIRO

Builds and explains GEMINI app logic

Produces technical documentation

Reasons about build, runtime, and deployment behavior

Preserves history and sequence in explanations

Human (Repository Owner)

Controls repository structure

Controls commits, tags, and reverts

Decides what gets saved and where

Explicit Exclusions for KIRO

No Git commands

No repository restructuring

No tagging or versioning

No file deletion or cleanup

No historical rewriting

3. Current System Status (Source of Truth)

As of the current state:

GEMINI Guardian is deployed and live

CloudFront delivery is active

Frontend enforces E.164 phone validation

International SMS support is intentional and verified

Vision panel is visible and in standby until triggered

Build and deployment behavior is documented truthfully

Non-blocking issues are explained, not hidden

This state is considered stable.

4. Core Logic Pillars (Must Always Hold)
4.1 Unified Input, Context-Aware Execution

All phone numbers are accepted in E.164 format

The system does not expose regional complexity to the user

Routing differences (U.S. vs international) are applied automatically

Validation occurs before submission, not after failure

4.2 Frontend as the First Safety Gate

Invalid phone input is blocked early

Users receive immediate visual feedback

Downstream failures are prevented by design

4.3 Observable Behavior Over Hidden Magic

What the user sees must reflect real system state

Standby vs active modes must be visible

The UI must never imply functionality that does not exist

5. Build & Deployment Reasoning (History Matters)
What Actually Happened

A first deployment attempt failed due to an incorrect S3 bucket

The bucket and CloudFront distribution were corrected based on prior state

A second deployment succeeded (upload + invalidation)

A PowerShell console error occurred after success

Cause: instructional text parsed as a command

Impact: cosmetic only

System state: unaffected

Why This History Is Preserved

It explains why the current configuration exists

It prevents future re-introduction of the same mistake

It proves the system was validated under real conditions

KIRO must never “clean this up” by omission.

6. Documentation Principles (For All Future Docs)

All documentation created by KIRO must:

Be jury-safe

Avoid speculation

Avoid legacy system names

Distinguish:

design intent

observed behavior

non-blocking issues

real failures

Preserve sequence and causality

Be usable without reading code

7. Change Evaluation Checklist (Before Doing Anything)

Before proposing or implementing any change, KIRO must answer:

Does this change preserve existing behavior?

Does it maintain the logic pillars in Section 4?

Does it respect the documented history in Section 5?

Does it improve clarity without hiding reality?

Is this change required, or merely aesthetic?

If any answer is unclear → stop and ask.

8. Definition of “Parity” in This Project

Parity does not mean:

identical code

identical infrastructure

identical tooling

Parity does mean:

identical user experience

identical safety guarantees

identical international behavior

identical failure prevention

identical explainability

9. When This Document Must Be Updated

This document should only be updated if:

a new capability changes system behavior

a deployment mechanism materially changes

a jury-relevant assumption changes

Minor refactors do not qualify.

10. Final Guardrail Statement

If the system works today, the burden of proof is on any change to explain why it should exist.

This document is the reference used to make that decision.