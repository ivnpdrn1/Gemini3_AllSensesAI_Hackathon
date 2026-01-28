ChatGPT_KIRO_INSTRUCTIONS_GEMINI_PARITY.md
Purpose

This document defines the authoritative logic sequence, design constraints, and acceptance rules governing the current AllSensesAI Gemini3 Guardian implementation.

It exists to:

Preserve build logic history

Prevent accidental regression

Ensure jury-safe parity

Define what “working” means — objectively and visibly

This is not a to-do list.
This is a state lock.

Roles & Responsibility Boundary
KIRO (Assistant)

KIRO is responsible for:

Building the Gemini Guardian application

Implementing UI, logic, validation, and behavior

Generating documentation artifacts

Producing deployable HTML builds

Ensuring runtime correctness

Providing jury-verifiable proof

KIRO is not responsible for:

Git operations

Repository structure

Branching, tagging, or commits

File placement decisions

Human Operator

The human operator is responsible for:

Saving documentation into the repository

Running deployment scripts

Managing version control

Approving final builds

This separation is intentional and must be preserved.

Canonical System Flow (Must Not Change)

The Guardian follows a 5-step linear workflow.
Each step must unlock the next and remain independently observable.

Step 1 — Configuration

Step 2 — Location Services

Step 3 — Voice Emergency Detection

Step 4 — Gemini Threat Analysis

Step 5 — Emergency Alerting

Any build that violates this flow is invalid.

Step 1 — Configuration (Critical Gate)
Required Behavior

Collect Victim Name

Collect Emergency Contact Phone

Enforce E.164 validation
Regex: ^\+[1-9]\d{6,14}$

Provide visible success/error feedback

Log proof output in a visible Step 1 Proof box

Button Rules

“Complete Step 1” must work

Button must be type="button"

Must not submit a form

Must prevent default behavior

Must unlock Step 2 on success

A non-responsive Step 1 button is a hard failure.

Step 2 — Location Services
Required Behavior

Must show Selected Location

Must display:

Latitude

Longitude

Timestamp

Source (Browser GPS / Demo)

Must provide a Google Maps link

Must show real-time proof logs

Location must remain available for later steps.

Step 3 — Voice Emergency Detection
Required Behavior

Microphone activation with permission handling

Live transcript display

Emergency keyword detection

Automatic emergency trigger on keyword match

Configurable Emergency Keywords (Required)

UI to add/remove keywords

Default keywords preloaded

Persistence via localStorage

Real-time update of detection logic

Display of enabled keywords in Trigger Rule panel

Regression of configurable keywords is not allowed.

Step 4 — Gemini Threat Analysis
Required Behavior

Uses Gemini 1.5 Pro

Accepts transcript + context

Produces:

Risk level

Confidence

Recommendation

Displays results visibly in UI

Preserves proof logs

This step does not send alerts — it informs Step 5.

Step 5 — Emergency Alerting (Non-Negotiable Rules)
Always Visible (Even Before Emergency)

The SMS Preview panel must always be visible, even when empty.

The following 8 fields must render with placeholders (“—”) on page load:

Victim

Risk

Recommendation

Message

Location

Map Link

Time

Action

This is victim trust UX — users must see what will be sent before it is sent.

Victim Name

Comes from Step 1

Fallback: "Unknown User"

Must appear in:

Structured preview fields

Raw SMS text

Any sent message simulation

Deterministic SMS Rule (Single Source of Truth)

The system must use one shared logic path for preview and sending.

The following functions must exist exactly once in the final build:

composeAlertPayload()

composeAlertSms(payload)

renderSmsPreviewFields(payload)

updateSmsPreview(reason)

Rules:

Preview === Sent message

Same inputs → same output

No duplication, no divergence

Step 5 Update Triggers (Must Exist)

updateSmsPreview() must be called when:

Page loads

Step 1 completes

Location updates (Step 2)

Threat analysis completes (Step 4)

Emergency trigger fires

Build Identity Proof (Jury Requirement)

Every deployable build must display a Build ID in two places:

Top build banner

Runtime Health Check panel

Format:

Build: GEMINI3-JURY-READY-YYYYMMDD-vN


This allows:

Screenshot verification

Cache validation

Jury trust

Regression detection

A build without visible identity is not acceptable.

Build Validation Rules (Fail-Hard)

Before declaring any build complete, validation must confirm:

Step 1 button is functional

All required functions exist exactly once

Step 5 fields render on load

No JavaScript runtime errors

Build ID visible in two locations

If any check fails, the build is invalid and must not be deployed.

Deployment Truth Rules

CloudFront URL must be reachable

Deployed page must match local build

No “it should be” claims — only visible proof

Any cosmetic errors must be documented explicitly

Blocking errors must stop deployment

Definition of Done (This State)

The system is considered complete and correct when:

Step 1 works reliably

Step 2–4 execute in order

Step 5 always shows structured preview

SMS content is deterministic and transparent

Victim name is visible and correct

Emergency keywords are configurable

Build identity is undeniable

Jury can verify behavior without explanation

This document reflects a known-good, jury-ready state.

Any future change must preserve these guarantees.