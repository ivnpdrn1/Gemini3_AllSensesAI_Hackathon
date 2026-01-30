# Browser Test Guide - CORS Fix Verification

**Status**: ✅ curl tests PASSED - Ready for browser testing  
**CloudFront URL**: https://dfc8ght8abwqc.cloudfront.net  
**Build ID**: GEMINI3-COLOMBIA-SMS-FIX-20260129-v3

## Pre-Test Checklist

- [ ] Open browser in **Incognito/Private mode** (to avoid cache)
- [ ] Open **DevTools** (F12) → **Network tab**
- [ ] Enable "Preserve log" in Network tab
- [ ] Filter by "Fetch/XHR" to see API calls

## Test Procedure

### Step 1: Load Page

1. Navigate to: https://dfc8ght8abwqc.cloudfront.net
2. Verify Build ID shows: `GEMINI3-COLOMBIA-SMS-FIX-20260129-v3`
3. Check Runtime Health panel shows "Gemini3 Client: Initializing..."

### Step 2: Complete Configuration

1. Enter name: "Test User"
2. Enter phone: "+573222063010" (or your Colombia number)
3. Click "✅ Complete Step 1"
4. Verify status shows: "✅ Configuration saved"

### Step 3: Enable Location

1. Click "📍 Enable Location" OR "🎯 Use Demo Location"
2. If using real GPS: Grant permission when prompted
3. Verify "Selected Location" panel appears with coordinates
4. Verify Google Maps link is visible

### Step 4: Trigger Emergency

**Option A: Voice Detection** (if microphone available)
1. Click "🎤 Start Voice Detection"
2. Grant microphone permission
3. Say: "help me I'm scared" (or any emergency keyword)
4. Wait for emergency modal to appear
5. Click "Proceed to Threat Analysis"

**Option B: Manual Test** (skip to Step 5)
1. Scroll to Step 5
2. Click "📱 Send Test SMS" button directly

### Step 5: Verify SMS Delivery

**Watch DevTools Network Tab**:

1. **OPTIONS Request** (preflight):
   - URL: `https://q4ouvfydgod6o734zbfipyi45q0lyuhx.lambda-url.us-east-1.on.aws/`
   - Method: OPTIONS
   - Status: **200 OK** (NOT "CORS error")
   - Response Headers should include:
     - `access-control-allow-origin: https://dfc8ght8abwqc.cloudfront.net`
     - `access-control-allow-methods: POST, OPTIONS`
     - `access-control-allow-headers: content-type`

2. **POST Request** (actual SMS):
   - URL: Same Lambda URL
   - Method: POST
   - Status: **200 OK** (NOT "CORS error")
   - Response Headers should include:
     - `access-control-allow-origin: https://dfc8ght8abwqc.cloudfront.net`
   - Response Body (Preview tab):
     ```json
     {
       "ok": true,
       "provider": "sns",
       "messageId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
       "toMasked": "+57***3010",
       "requestId": "...",
       "timestamp": "..."
     }
     ```

**Watch UI "SMS Delivery Proof" Panel**:

Should show:
```
Status: SENT
Provider: sns
SNS Message ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Destination: +57***3010
HTTP Status: 200
Request ID: ...
Timestamp: ...
```

**Check Colombia Phone**:
- SMS should arrive within 5-30 seconds
- Message should contain:
  - "🚨 EMERGENCY ALERT"
  - Victim name: "Test User"
  - Risk level: "HIGH"
  - Location coordinates
  - Google Maps link
  - Timestamp

## Success Criteria

✅ **PASS** if ALL of these are true:
- [ ] DevTools shows OPTIONS request with Status 200 (not CORS error)
- [ ] DevTools shows POST request with Status 200 (not CORS error)
- [ ] Response body is visible in DevTools (not blocked)
- [ ] UI shows "Status: SENT" with MessageId
- [ ] SMS arrives on Colombia phone within 30 seconds

❌ **FAIL** if ANY of these occur:
- [ ] DevTools shows "CORS error" or "(failed)"
- [ ] UI shows "FAILED / FETCH_EXCEPTION"
- [ ] Response body is blocked/empty in DevTools
- [ ] No MessageId in UI
- [ ] SMS doesn't arrive after 60 seconds

## Troubleshooting

### Issue: Still seeing CORS error

**Cause**: CloudFront serving cached old HTML

**Fix**:
```powershell
# Create CloudFront invalidation
aws cloudfront create-invalidation \
  --distribution-id E2NIUI2KOXAO0Q \
  --paths "/*"

# Wait 2-3 minutes, then hard refresh browser
# Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
```

### Issue: OPTIONS succeeds but POST fails

**Cause**: Request payload or headers incorrect

**Fix**: Check DevTools Console for JavaScript errors

### Issue: POST succeeds but no SMS

**Cause**: SNS delivery issue (not CORS)

**Fix**: Check Lambda logs:
```powershell
aws logs tail /aws/lambda/allsenses-sms-production \
  --since 5m --region us-east-1
```

### Issue: Wrong Build ID showing

**Cause**: CloudFront cache

**Fix**: Same as "Still seeing CORS error" above

## Expected DevTools Screenshots

### OPTIONS Request (Success)
```
Status: 200 OK
Method: OPTIONS
Type: preflight

Response Headers:
  access-control-allow-origin: https://dfc8ght8abwqc.cloudfront.net
  access-control-allow-methods: POST, OPTIONS
  access-control-allow-headers: content-type
  access-control-max-age: 86400
```

### POST Request (Success)
```
Status: 200 OK
Method: POST
Type: fetch

Response Headers:
  access-control-allow-origin: https://dfc8ght8abwqc.cloudfront.net
  content-type: application/json

Response Body:
  {
    "ok": true,
    "provider": "sns",
    "messageId": "1621488f-8128-5881-b111-29799273ad3e",
    ...
  }
```

## Quick Test Command

If browser test fails, verify Lambda is still working:
```powershell
.\Gemini3_AllSensesAI\deployment\test-cors-fix-complete.ps1
```

Should show: "✅ ALL TESTS PASSED"

## Contact

If tests fail after following troubleshooting steps, provide:
1. Screenshot of DevTools Network tab (showing OPTIONS + POST requests)
2. Screenshot of UI "SMS Delivery Proof" panel
3. Browser console errors (if any)
4. Lambda logs from last 5 minutes
