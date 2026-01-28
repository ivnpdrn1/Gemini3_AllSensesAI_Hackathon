📞 SMS Origination & International Routing — GEMINI Design Rationale
Purpose

This section documents why SMS delivery behaves differently for U.S. versus non-U.S. destinations, and how GEMINI correctly handles both cases while maintaining compliance, deliverability, and user trust.

This is an intentional design decision, not an implementation accident.

🇺🇸 United States — Registered Origination (10DLC)

In the United States, Application-to-Person (A2P) SMS traffic is regulated by mobile carriers (AT&T, Verizon, T-Mobile).

Key characteristics:

Messages must originate from registered 10-digit long codes (10DLC)

Each origination number is associated with:

An approved sender identity

A declared messaging use case

Carrier-reviewed compliance metadata

Why this matters:

Unregistered or generic origination routes are frequently filtered or blocked

Emergency or safety-related notifications require high deliverability and trust

For this reason, GEMINI uses registered U.S. origination numbers when delivering SMS to U.S. recipients.

Important clarification:
10DLC is not a phone number format.
It is a U.S.-only regulatory and carrier trust framework.

🌎 International Destinations — E.164 Routing

Outside the United States:

The 10DLC framework does not exist

Carrier requirements differ by country

SMS delivery relies on international routing agreements

For international destinations, GEMINI:

Requires destination numbers in E.164 format

Delegates routing to the messaging provider’s international infrastructure

Does not attempt to apply U.S.-specific origination rules

Supported international destinations include:

🇨🇴 Colombia (+57)

🇲🇽 Mexico (+52)

🇻🇪 Venezuela (+58)

Unified Input, Country-Aware Execution

At the system boundary, GEMINI uses E.164-formatted phone numbers for all destinations.

Examples:

+14155552671 (United States)

+573001234567 (Colombia)

+5215512345678 (Mexico)

+584121234567 (Venezuela)

Although the input format is unified, execution differs internally based on destination country.

Provider-Managed Routing (Internal Behavior)

The messaging provider automatically applies the correct delivery path:

Destination	Internal Routing Behavior
🇺🇸 United States	Uses registered U.S. origination (10DLC)
🌎 Non-U.S.	Uses international SMS routing (E.164-based)

As a result:

U.S. messages comply with carrier regulations

International messages follow country-appropriate routing rules

No manual branching is required at the application layer

Frontend Validation & User Experience

To ensure correctness and clarity, GEMINI enforces the following at the UI level:

Phone Number Validation

Required format: E.164

Regex:
^\+[1-9]\d{6,14}$

Examples shown to users

+1XXXXXXXXXX

+57XXXXXXXXXX

+52XXXXXXXXXX

+58XXXXXXXXXX

Behavior

Invalid numbers are blocked before submission

Valid numbers receive immediate confirmation feedback

This prevents downstream delivery failures and improves user trust

Design Principles

✅ Use global standards (E.164) at system boundaries

✅ Apply country-specific compliance only where required

✅ Delegate carrier-specific logic to the messaging provider

❌ Do not expose regulatory complexity to end users

❌ Do not apply U.S.-only rules to international traffic

Authoritative Statement

GEMINI automatically applies the correct SMS origination and routing strategy based on the destination country, ensuring regulatory compliance, high deliverability, and consistent behavior across regions.

Build Reference

GEMINI Build: GEMINI3-E164-PARITY-20260128

Scope: U.S. + International SMS delivery