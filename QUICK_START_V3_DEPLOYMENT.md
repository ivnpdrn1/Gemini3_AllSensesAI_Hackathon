# Quick Start: v3 Deployment (Colombia SMS + UI Fix)

**Build ID:** `GEMINI3-JURY-READY-VIDEO-SMS-20260128-v3`  
**Status:** ✅ BUILD COMPLETE - READY FOR DEPLOYMENT

## What's New in v3

### Part A: Colombia SMS Fixes
- ✅ Manual "Send Test SMS" works regardless of risk level (no gating)
- ✅ Enhanced Delivery Proof panel (Status, Provider, SNS Message ID, Request ID, Destination, HTTP Status, Timestamp, Error Code, Error Message)
- ✅ Enhanced proof logging for debugging

### Part B: UI Fix
- ✅ Fixed "Waiting for threat analysis..." stuck message
- ✅ Initial status: "Ready to send alert (complete Steps 1-4 first)"
- ✅ After analysis: "🚨 Ready to send alert | Auto-alert will send on HIGH/CRITICAL" or "✅ Ready to send alert (manual test available)"

## Deployment Steps

### Step 1: Check SNS Configuration (CRITICAL)

```powershell
.\Gemini3_AllSensesAI\deployment\check-sns-config.ps1
```

**This checks:**
- SNS monthly spend limit (must NOT be $0)
- Delivery status logging enabled
- Colombia (+57) not blocked

**If checks fail:** Follow the instructions in the output to fix SNS configuration.

### Step 2: Deploy Backend + Frontend

```powershell
.\Gemini3_AllSensesAI\deployment\deploy-sms-backend.ps1
```

**This will:**
1. Deploy Lambda function (if not already deployed)
2. Deploy API Gateway (if not already deployed)
3. Get API Gateway URL from CloudFormation
4. Update HTML with real API URL
5. Deploy to CloudFront
6. Create invalidation and wait for completion
7. Print CloudFront URL

**Expected output:**
```
✅ Lambda stack deployed: gemini3-sms-backend
✅ API Gateway URL: https://abc123.execute-api.us-east-1.amazonaws.com/prod/send-sms
✅ Updated HTML with API URL
✅ Deployed to CloudFront: https://dfc8ght8abwqc.cloudfront.net
✅ Invalidation created: I2ABCDEFGHIJKL
⏳ Waiting for invalidation to complete...
✅ Invalidation complete
```

### Step 3: Verify Deployment

```powershell
.\Gemini3_AllSensesAI\verify-colombia-sms.ps1
```

**This checks:**
- CloudFront URL accessible
- Build ID visible in UI
- SMS API URL configured
- Manual test button present

### Step 4: Manual Test (Colombia +57)

1. **Open CloudFront URL** (from deployment output)

2. **Complete Step 1:**
   - Name: `Demo User`
   - Phone: `+573222063010` (Colombia number)
   - Click "✅ Complete Step 1"

3. **Complete Step 2:**
   - Click "📍 Enable Location" OR "🎯 Use Demo Location"

4. **Complete Step 3 (optional for manual test):**
   - Click "🎤 Start Voice Detection"
   - Say something (or skip this step)

5. **Send Test SMS:**
   - Click "📤 Send Test SMS" button
   - Confirm in dialog
   - Watch Delivery Proof panel update

6. **Verify Delivery:**
   - Check Delivery Proof panel for status
   - Check phone for SMS (5-30 seconds)
   - Verify message matches preview EXACTLY

## Done Definition

✅ CloudFront URL accessible  
✅ Build ID visible: `GEMINI3-JURY-READY-VIDEO-SMS-20260128-v3`  
✅ Step 1 configured with Colombia +57  
✅ Step 5 preview shows SMS text  
✅ Click "Send Test SMS" (works on MEDIUM risk)  
✅ Colombia phone receives the SMS  
✅ Message matches preview EXACTLY  
✅ Delivery Proof panel shows all fields  
✅ Step 5 status shows "Ready to send alert" (never stuck)  
✅ CloudWatch logs show successful delivery  

## Troubleshooting

### SMS Not Sending

**Check SNS Configuration:**
```powershell
.\Gemini3_AllSensesAI\deployment\check-sns-config.ps1
```

**Common Issues:**
1. **SNS spend limit is $0** → Set to $5-$10 in AWS Console
2. **Colombia blocked** → Check country-specific settings
3. **Sandbox mode** → Request production access via AWS Support
4. **Invalid phone format** → Must be E.164 (+573222063010)

**See full troubleshooting guide:**
```
Gemini3_AllSensesAI/SMS_DELIVERY_RUNBOOK.md
```

### Delivery Proof Shows Error

**Check Delivery Proof panel for:**
- Error Code (e.g., VALIDATION_ERROR, NETWORK_ERROR)
- Error Message (human-readable description)

**Check CloudWatch Logs:**
```powershell
aws logs tail /aws/lambda/gemini3-sms-handler --follow
```

### Step 5 Status Stuck

**v3 Fix:** This should NOT happen in v3. If it does:
1. Check browser console for errors
2. Verify Build ID is v3: `GEMINI3-JURY-READY-VIDEO-SMS-20260128-v3`
3. Clear browser cache and reload

## Key Features

### Manual SMS Test (NO RISK GATING)
- Works on ANY risk level (LOW, MEDIUM, HIGH, CRITICAL)
- Bypasses auto-trigger gating
- Jury demo safe
- Requires Step 1 completion only

### Enhanced Delivery Proof
- Status (color-coded)
- Provider (SNS)
- SNS Message ID
- Request ID
- Destination (masked)
- HTTP Status
- Timestamp
- Error Code (on failure)
- Error Message (on failure)

### Step 5 Status Messages
- Initial: "Ready to send alert (complete Steps 1-4 first)"
- After HIGH/CRITICAL: "🚨 Ready to send alert | Auto-alert will send on HIGH/CRITICAL"
- After other levels: "✅ Ready to send alert (manual test available)"
- NEVER: "Waiting for threat analysis..." (eliminated)

## Files

**Build:**
- `Gemini3_AllSensesAI/create-colombia-sms-fix-v3.py` - Build script
- `Gemini3_AllSensesAI/gemini3-guardian-jury-ready-video-sms.html` - Output (117 KB)

**Backend:**
- `Gemini3_AllSensesAI/backend/sms/lambda_handler.py` - Lambda function
- `Gemini3_AllSensesAI/backend/sms/template.yaml` - CloudFormation template

**Deployment:**
- `Gemini3_AllSensesAI/deployment/check-sns-config.ps1` - SNS config checker
- `Gemini3_AllSensesAI/deployment/deploy-sms-backend.ps1` - Deployment script
- `Gemini3_AllSensesAI/verify-colombia-sms.ps1` - Verification script

**Documentation:**
- `Gemini3_AllSensesAI/SMS_DELIVERY_RUNBOOK.md` - Troubleshooting guide
- `TASK_5_COLOMBIA_SMS_V3_COMPLETE.md` - Full implementation summary
- `Gemini3_AllSensesAI/QUICK_START_V3_DEPLOYMENT.md` - This document

## Support

**For issues:**
1. Check `SMS_DELIVERY_RUNBOOK.md` for troubleshooting
2. Check CloudWatch logs for backend errors
3. Check browser console for frontend errors
4. Verify SNS configuration with `check-sns-config.ps1`

---

**Ready to deploy?** Run: `.\Gemini3_AllSensesAI\deployment\deploy-sms-backend.ps1`
