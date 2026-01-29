KIRO INSTRUCTION BLOCK — Fix “CORS error / Failed to fetch” (OPTIONS 200, POST blocked)
Evidence (from screenshots)

CloudFront page loads fine.

Network tab shows:

…lambda-url… preflight (OPTIONS) → 200

…lambda-url… fetch (POST) → CORS error

UI shows: “Failed to fetch. Likely CORS or network issue.”

Therefore: POST response is not passing CORS, even though OPTIONS does.

Goal

Ensure the Lambda Function URL returns correct CORS headers on EVERY POST response path (success + validation error + exception), not just on OPTIONS.

Step 1 — Reproduce and confirm the exact failure

Open the app in Incognito.

Trigger SMS (manual “Send Test SMS” is enough).

In DevTools → Network:

Confirm OPTIONS is 200.

Confirm POST is “CORS error”.

Acceptance check: we reproduce the same pattern seen in screenshots.

Step 2 — Verify CORS headers using curl (bypasses browser CORS blocking)

Run these from terminal (replace ORIGIN with your CloudFront domain):

OPTIONS test
curl -i -X OPTIONS "https://q4ouvfydgod6o734zbfipyi45q0lyuhx.lambda-url.us-east-1.on.aws/" \
  -H "Origin: https://dfc8ght8abwqc.cloudfront.net" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type"

POST test (Format A)
curl -i -X POST "https://q4ouvfydgod6o734zbfipyi45q0lyuhx.lambda-url.us-east-1.on.aws/" \
  -H "Origin: https://dfc8ght8abwqc.cloudfront.net" \
  -H "Content-Type: application/json" \
  --data '{"to":"+573222063010","message":"CORS header test","buildId":"test","victimName":"Demo","meta":{"source":"curl"}}'


What to look for in BOTH responses:

Access-Control-Allow-Origin: https://dfc8ght8abwqc.cloudfront.net OR *

Access-Control-Allow-Methods: POST,OPTIONS

Access-Control-Allow-Headers: content-type (and any others you use)

If OPTIONS has these but POST does not → confirmed root cause.

Step 3 — Implement a single “cors_headers()” helper and attach it everywhere

In lambda_function.py:

Create a helper like:

cors_headers(origin) returning:

Access-Control-Allow-Origin

Access-Control-Allow-Methods

Access-Control-Allow-Headers

Access-Control-Max-Age

(Optional but useful) Vary: Origin

Detect origin from request headers:

origin = event.headers.get("origin") or event.headers.get("Origin")

If origin is your CloudFront domain → echo it back.

Otherwise, safe fallback to *.

Ensure every return statement includes:

headers = cors_headers(origin)

This includes:

OPTIONS preflight return

Success return (200)

Validation return (400)

Exception return (500)

Critical: Many teams fix OPTIONS and forget that the POST “error path” returns without CORS headers — that causes exactly your screenshots (OPTIONS 200, POST CORS error).

Step 4 — Eliminate redirect-based CORS breakage

From Lambda Function URL, a redirect can also appear as a CORS failure.

Add logging and verify:

The Lambda is not returning 301/302.

The function URL is HTTPS and matches exactly what frontend uses.

No trailing spaces/newlines in SMS_API_URL.

Acceptance check: curl POST returns 200/400/500 with CORS headers present, never 301/302.

Step 5 — Deploy Lambda and verify in browser

Deploy updated Lambda code.

In Incognito, repeat the manual test:

Network shows:

OPTIONS 200

POST 200 (not CORS error)

UI “SMS Delivery Proof” shows:

Status success and MessageId OR a real error with HTTP status (but not “Failed to fetch”)

Acceptance criteria:

✅ OPTIONS 200 with correct headers

✅ POST 200 with correct headers

✅ POST 400/500 still includes correct headers

✅ Chrome Network no longer shows “CORS error”

✅ “Failed to fetch” disappears unless there is a real connectivity outage

Step 6 — Add a small “CORS proof” to logs + docs

Log the resolved origin and whether allow-origin is echoing or *.

Add a short markdown doc: CORS_POST_HEADER_PROOF.md with:

curl outputs (headers visible)

browser screenshot of Network showing POST 200

Final Deliverable

Updated lambda_function.py with:

unified CORS header helper

headers on all responses

origin echo/allowlist logic

no redirect behavior

Proof: curl + browser Network screenshot.


**************************************


Summary
I've successfully diagnosed and fixed the CORS error that was causing "Failed to fetch" in the browser.

🔍 Root Cause Identified
The issue was duplicate/conflicting CORS headers:

Lambda Function URL CORS config was adding: Access-Control-Allow-Origin: https://dfc8ght8abwqc.cloudfront.net
Lambda code was ALSO adding: Access-Control-Allow-Origin: *
Combined result: Access-Control-Allow-Origin: *,https://dfc8ght8abwqc.cloudfront.net ❌
Browsers reject responses with multiple Allow-Origin values
✅ Solution Implemented
Coordinated Lambda code with Function URL CORS configuration:

Function URL handles: Access-Control-Allow-Origin (automatically echoes request origin)
Lambda code handles: Access-Control-Allow-Methods and Access-Control-Allow-Headers
Result: Clean, single-value CORS headers on all responses ✅
📋 Verification Complete
Automated Testing (PowerShell):

✅ OPTIONS → 200 with correct CORS headers
✅ POST (success) → 200 with correct CORS headers + MessageId
✅ POST (error) → 400 with correct CORS headers
✅ No duplicate headers
✅ Origin matches exactly
📁 Files Created
lambda-auto-sms-fix-cors-corrected.py - Fixed Lambda handler
deploy-cors-fix.ps1 - Deployment script
test-cors-headers-powershell.ps1 - CORS verification script
CORS_POST_HEADER_PROOF.md - Detailed verification with curl outputs
CORS_FIX_COMPLETE_SUMMARY.md - Technical summary
BROWSER_TEST_CORS_FIX.md - Quick browser test guide
🚀 Deployment Status
✅ DEPLOYED TO PRODUCTION

Function: allsenses-sms-production
Last Modified: 2026-01-29T23:30:57.000+0000
All automated tests passing
🎯 Next Step
Manual Browser Test (2 minutes):

Open https://dfc8ght8abwqc.cloudfront.net in Incognito
DevTools → Network + Console tabs
Click "Send Test SMS" or say "help me"
Verify: POST returns 200 (NOT "CORS error"), console shows [SMS][SUCCESS], SMS received
The CORS issue is fixed and verified via automated testing. Ready for final browser verification.