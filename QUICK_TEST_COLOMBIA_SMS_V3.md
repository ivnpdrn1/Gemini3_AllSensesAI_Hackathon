# Quick Test Guide - Colombia SMS Fix V3

## Pre-Deployment

```powershell
# 1. Run SNS preflight check
.\Gemini3_AllSensesAI\deployment\check-sns-preflight.ps1

# 2. Deploy v3 build
.\Gemini3_AllSensesAI\deployment\deploy-colombia-sms-fix-v3.ps1
```

---

## Testing Checklist

### ✅ Test 1: Build ID Verification

**Open CloudFront URL in INCOGNITO window**

1. Check top banner shows: `Build: GEMINI3-COLOMBIA-SMS-FIX-20260129-v3`
2. Check Runtime Health Check panel shows: `Loaded Build ID: GEMINI3-COLOMBIA-SMS-FIX-20260129-v3`

**Expected:** Both show v3 (NOT v1)

---

### ✅ Test 2: Step 5 Status Updates

1. Complete Step 1 (enter name + phone)
2. Complete Step 2 (enable location)
3. Complete Step 3 (start voice detection)
4. Complete Step 4 (analyze with Gemini3)
5. **Check Step 5 status immediately after Step 4 completes**

**Expected:** 
- Status updates to "Ready to send alert (manual test available)"
- Status does NOT say "Waiting for threat analysis..."

---

### ✅ Test 3: Successful SMS Delivery

1. Enter Colombia phone number in Step 1: `+573222063010`
2. Complete Steps 1-4
3. Click "Send Test SMS" button
4. Check Delivery Proof panel

**Expected:**
```
Status: SENT
Provider: sns
Destination: +57******3010
HTTP Status: 200
SNS Message ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx (real UUID)
Request ID: (AWS request ID)
```

**NOT Expected:**
- Status: FAILED
- Error Code: HTTP_ERROR
- SNS Message ID: "-"

5. Check Colombia phone for SMS (allow 5-30 seconds)

**Expected:** SMS arrives with emergency alert text

---

### ✅ Test 4: Failed SMS Delivery (Invalid Number)

1. Enter invalid phone number in Step 1: `+1234567890`
2. Complete Steps 1-4
3. Click "Send Test SMS" button
4. Check Delivery Proof panel

**Expected:**
```
Status: FAILED
Error Code: (NOT "HTTP_ERROR", should be "SNS_PUBLISH_FAILED" or similar)
Error Message: (descriptive error from backend)
HTTP Status: 502 or 500 (NOT 200)
```

---

### ✅ Test 5: E.164 Validation

Try these phone numbers and verify validation:

**Valid:**
- `+573222063010` ✅ (Colombia mobile)
- `+12025551234` ✅ (US)
- `+447911123456` ✅ (UK)

**Invalid:**
- `3222063010` ❌ (missing +)
- `+57322206301` ❌ (wrong length)
- `+0573222063010` ❌ (starts with 0)
- `+57-322-206-3010` ❌ (has dashes)

**Expected:** Invalid numbers rejected with alert message

---

## Console Logs to Check

### Successful SMS (HTTP 200)

```
[SMS][REQUEST] Sending SMS (MANUAL)...
[SMS][FETCH] Starting fetch request to: https://...
[SMS][RESPONSE] ✅ HTTP 200 in XXXms
[SMS][SUCCESS] ✅ SMS sent successfully
[SMS][SUCCESS] Message ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
[SMS][UI] Delivery status updated: { status: 'SENT', ... }
```

### Failed SMS (HTTP 502/500)

```
[SMS][REQUEST] Sending SMS (MANUAL)...
[SMS][FETCH] Starting fetch request to: https://...
[SMS][RESPONSE] ✅ HTTP 502 in XXXms
[SMS][ERROR] ❌ SMS sending failed
[SMS][ERROR] Error message: SNS publish failed: ...
[SMS][ERROR] result.ok: false
[SMS][UI] Delivery status updated: { status: 'FAILED', ... }
```

---

## Backend Logs to Check (CloudWatch)

### Successful Publish

```json
{
  "level": "INFO",
  "message": "SNS publish successful",
  "messageId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "destination": "+57******3010"
}
```

### Failed Publish

```json
{
  "level": "ERROR",
  "message": "SNS publish failed",
  "error": "InvalidParameter: ...",
  "destination": "+57******3010"
}
```

---

## Common Issues

### Issue: Build ID shows v1 instead of v3

**Solution:**
1. Clear browser cache (Ctrl+Shift+Delete)
2. Open in incognito window
3. Wait 5 minutes for CloudFront propagation
4. Check S3 object has cache-control headers:
   ```powershell
   aws s3api head-object --bucket <bucket> --key index.html
   ```

### Issue: SMS not arriving

**Solution:**
1. Check SNS spend limit:
   ```powershell
   aws sns get-sms-attributes --region us-east-1
   ```
2. Check SMS sandbox status
3. Verify phone number is E.164 format
4. Check CloudWatch logs for SNS errors

### Issue: Delivery Proof shows "HTTP_ERROR"

**Solution:**
- This should NOT happen with v3
- Verify Build ID is v3 (not v1)
- Check Lambda is using v4 handler
- Check backend logs for actual error

---

## Quick Verification Commands

```powershell
# Check SNS configuration
aws sns get-sms-attributes --region us-east-1

# Check Lambda function
aws lambda get-function --function-name allsenses-sms-handler --region us-east-1

# Check S3 object metadata
aws s3api head-object --bucket <bucket-name> --key index.html

# Check CloudFront invalidation status
aws cloudfront get-invalidation --distribution-id <dist-id> --id <invalidation-id>

# Test Lambda directly
aws lambda invoke --function-name allsenses-sms-handler --payload file://test-payload.json response.json
```

---

## Test Payload Example

Save as `test-payload.json`:

```json
{
  "to": "+573222063010",
  "message": "Test SMS from AllSensesAI",
  "buildId": "GEMINI3-COLOMBIA-SMS-FIX-20260129-v3",
  "meta": {
    "victimName": "Test User",
    "risk": "TEST",
    "confidence": "100%",
    "recommendation": "This is a test",
    "triggerMessage": "Manual test",
    "triggerType": "MANUAL",
    "lat": 4.7110,
    "lng": -74.0721,
    "mapUrl": "https://www.google.com/maps?q=4.7110,-74.0721",
    "timestampIso": "2026-01-29T12:00:00.000Z",
    "action": "Test"
  }
}
```

---

## Success Criteria

All of these must pass:

- ✅ Build ID shows v3 in UI
- ✅ Step 5 status updates after analysis
- ✅ Successful SMS shows SENT with MessageId
- ✅ Failed SMS shows proper error (not "HTTP_ERROR")
- ✅ SMS arrives on Colombia phone
- ✅ E.164 validation works

