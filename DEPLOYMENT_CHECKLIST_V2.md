# Deployment Checklist - v2 Colombia SMS

**Build:** `GEMINI3-JURY-READY-VIDEO-SMS-20260128-v2`  
**Date:** 2026-01-28

---

## Pre-Deployment Checklist

### AWS Prerequisites
- [ ] AWS CLI installed and configured
- [ ] AWS SAM CLI installed (`sam --version`)
- [ ] AWS credentials have necessary permissions
- [ ] Default region set (recommend: us-east-1)

### SNS Configuration (CRITICAL)
- [ ] SNS monthly spend limit > $0 (set to $5-$10)
- [ ] Delivery status logging enabled (recommended)
- [ ] Colombia (+57) not blocked in country settings
- [ ] Default SMS type set to "Transactional"

**Verify with:**
```powershell
.\Gemini3_AllSensesAI\deployment\check-sns-config.ps1
```

### CloudFront/S3 Resources
- [ ] S3 bucket exists: `gemini3-guardian-prod-20260127120521`
- [ ] CloudFront distribution exists: `E2NIUI2KOXAO0Q`
- [ ] CloudFront URL accessible: https://dfc8ght8abwqc.cloudfront.net

---

## Deployment Steps

### Step 1: Pre-Deployment Validation
```powershell
# Check SNS configuration
.\Gemini3_AllSensesAI\deployment\check-sns-config.ps1
```

**Expected Output:**
- ✅ Spend limit > $0
- ✅ SMS type: Transactional
- ⚠️ Delivery logging (optional but recommended)
- ✅ Lambda role (will be created if missing)
- ✅ AWS CLI configured

**If any CRITICAL checks fail, STOP and fix before proceeding.**

### Step 2: Deploy Backend + Frontend
```powershell
# Deploy everything
.\Gemini3_AllSensesAI\deployment\deploy-sms-backend.ps1
```

**Expected Steps:**
1. [0/7] SNS configuration check
2. [1/7] Build HTML with SMS integration
3. [2/7] Deploy Lambda + API Gateway (SAM)
4. [3/7] Retrieve API Gateway URL
5. [4/7] Update HTML with API URL
6. [5/7] Upload to S3
7. [6/7] Create CloudFront invalidation
8. [7/7] Wait for invalidation (1-3 minutes)

**Expected Time:** 3-6 minutes

**Success Indicators:**
- ✅ Lambda function deployed
- ✅ API Gateway URL retrieved
- ✅ HTML updated with API URL
- ✅ S3 upload successful
- ✅ CloudFront invalidation completed

### Step 3: Backend Verification
```powershell
# Test Lambda + SNS
.\Gemini3_AllSensesAI\verify-colombia-sms.ps1
```

**Expected Tests:**
1. Lambda direct invocation
2. Lambda logs check
3. SNS delivery logs check (may take 1-2 minutes)
4. Frontend verification checklist

**Success Indicators:**
- ✅ Lambda returns 200 status
- ✅ Response includes messageId
- ✅ Lambda logs show "SMS published successfully"
- ⏳ SNS logs show "SUCCESS" (wait 1-2 minutes)

---

## Frontend Testing

### Step 4: Browser Verification

1. **Open CloudFront URL**
   ```
   https://dfc8ght8abwqc.cloudfront.net
   ```

2. **Hard Refresh**
   - Windows: Ctrl+Shift+R
   - Mac: Cmd+Shift+R

3. **Verify Build ID**
   - [ ] Top stamp shows: `Build: GEMINI3-JURY-READY-VIDEO-SMS-20260128-v2`
   - [ ] Runtime Health Check shows: `Loaded Build ID: GEMINI3-JURY-READY-VIDEO-SMS-20260128-v2`

4. **Complete Step 1**
   - [ ] Enter victim name
   - [ ] Enter Colombia phone: `+573222063010`
   - [ ] Click "Complete Step 1" button
   - [ ] Configuration locks successfully
   - [ ] "Send Test SMS" button appears

5. **Test SMS Sending**
   - [ ] Click "Send Test SMS" button
   - [ ] Confirm dialog appears
   - [ ] Click OK
   - [ ] Delivery Proof panel appears
   - [ ] Status changes: NOT_SENT → SENDING → SENT
   - [ ] Destination shows: `+57***3010`
   - [ ] Timestamp appears
   - [ ] Message ID appears

6. **Verify SMS Arrival**
   - [ ] SMS arrives at Colombia phone within 30 seconds
   - [ ] Message content matches preview exactly
   - [ ] All 8 fields present in SMS

---

## Post-Deployment Verification

### CloudWatch Logs

**Lambda Logs:**
```powershell
aws logs tail /aws/lambda/gemini3-sms-sender-prod --follow
```

**Expected Output:**
```
[SMS-LAMBDA] Received event
[SMS-LAMBDA] Publishing SMS to +57***3010
[SMS-LAMBDA] Message length: XXX chars
[SMS-LAMBDA] SMS published successfully. MessageId: abc123
```

**SNS Delivery Logs (wait 1-2 minutes):**
```powershell
$accountId = aws sts get-caller-identity --query Account --output text
aws logs tail /aws/sns/us-east-1/$accountId/DirectPublishToPhoneNumber --follow
```

**Expected Output:**
```json
{
  "status": "SUCCESS",
  "phoneNumber": "+573222063010",
  "messageId": "abc123",
  "priceInUSD": 0.02
}
```

### Browser Console Logs

**Expected Output:**
```
[SMS-CONFIG] API URL: https://[your-api-gateway-url]/prod/send-sms
[SMS][REQUEST] Sending SMS to backend...
[SMS][SUCCESS] SMS sent successfully: {messageId: "abc123", ...}
[SMS][UI] Delivery status updated: {status: "SENT", ...}
```

---

## Rollback Procedure

If deployment fails or SMS doesn't work:

### Option 1: Rollback Frontend Only
```powershell
# Re-upload previous version
aws s3 cp Gemini3_AllSensesAI/gemini3-guardian-jury-ready-video.html `
  s3://gemini3-guardian-prod-20260127120521/index.html `
  --content-type "text/html" `
  --cache-control "no-cache, no-store, must-revalidate"

# Invalidate CloudFront
aws cloudfront create-invalidation `
  --distribution-id E2NIUI2KOXAO0Q `
  --paths "/*"
```

### Option 2: Rollback Backend
```powershell
# Delete Lambda stack
aws cloudformation delete-stack --stack-name gemini3-sms-backend

# Wait for deletion
aws cloudformation wait stack-delete-complete --stack-name gemini3-sms-backend
```

### Option 3: Full Rollback
Run both Option 1 and Option 2.

---

## Troubleshooting

### Issue: SNS Config Check Fails

**Symptom:** `check-sns-config.ps1` shows critical failures

**Fix:**
1. Go to AWS Console → SNS → Text messaging (SMS) → Preferences
2. Set "Account spend limit" to $5 or $10
3. Save and wait 1-2 minutes
4. Run check script again

### Issue: SAM Deploy Fails

**Symptom:** `sam deploy` returns error

**Common Causes:**
- IAM permissions insufficient
- Stack already exists with different parameters
- Region mismatch

**Fix:**
```powershell
# Check existing stack
aws cloudformation describe-stacks --stack-name gemini3-sms-backend

# Delete and redeploy
aws cloudformation delete-stack --stack-name gemini3-sms-backend
aws cloudformation wait stack-delete-complete --stack-name gemini3-sms-backend
.\Gemini3_AllSensesAI\deployment\deploy-sms-backend.ps1
```

### Issue: SMS Not Arriving

**Symptom:** Delivery Proof shows SENT but no SMS received

**Diagnosis:**
```powershell
# Check SNS delivery logs (wait 2-3 minutes)
$accountId = aws sts get-caller-identity --query Account --output text
aws logs tail /aws/sns/us-east-1/$accountId/DirectPublishToPhoneNumber --since 5m
```

**Common Causes:**
- SNS spend limit reached
- Phone number opted out
- Country blocked
- Carrier delay (can take up to 5 minutes)

**Fix:** See `Gemini3_AllSensesAI/SMS_DELIVERY_RUNBOOK.md`

### Issue: Build ID Not Updating

**Symptom:** CloudFront still shows v1 build ID

**Fix:**
```powershell
# Hard refresh browser
# Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)

# Check CloudFront cache
aws cloudfront get-invalidation `
  --distribution-id E2NIUI2KOXAO0Q `
  --id [invalidation-id]

# If still cached, create new invalidation
aws cloudfront create-invalidation `
  --distribution-id E2NIUI2KOXAO0Q `
  --paths "/*"
```

---

## Success Criteria

Deployment is successful when ALL of the following are true:

### Backend
- [x] Lambda function deployed
- [x] API Gateway endpoint accessible
- [x] Lambda logs show successful SMS publish
- [x] SNS logs show successful delivery

### Frontend
- [x] CloudFront shows Build ID v2
- [x] Delivery Proof panel visible
- [x] Manual test button works
- [x] Auto-trigger works (HIGH/CRITICAL risk)

### End-to-End
- [x] SMS arrives at Colombia phone
- [x] Message matches preview exactly
- [x] Delivery time < 30 seconds
- [x] Delivery Proof shows SENT status

### Zero Regressions
- [x] All Step 1-5 UI preserved
- [x] Video panel preserved
- [x] SMS preview preserved
- [x] Configurable keywords preserved
- [x] Build ID visible in 2 locations

**If all criteria met: DEPLOYMENT SUCCESSFUL** ✅

---

## Documentation References

- **Quick Start:** `Gemini3_AllSensesAI/QUICK_START_COLOMBIA_SMS.md`
- **Troubleshooting:** `Gemini3_AllSensesAI/SMS_DELIVERY_RUNBOOK.md`
- **Implementation:** `Gemini3_AllSensesAI/SMS_DELIVERY_COLOMBIA_COMPLETE.md`
- **Canonical Logic:** `Gemini3_AllSensesAI/ChatGPT_KIRO_INSTRUCTIONS_GEMINI_PARITY.md`

---

**Estimated Total Time:** 6-10 minutes  
**Last Updated:** 2026-01-28  
**Version:** v2

