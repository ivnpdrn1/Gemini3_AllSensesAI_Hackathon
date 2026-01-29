# SMS Delivery Runbook - Colombia +57 International SMS

**Build ID:** `GEMINI3-JURY-READY-VIDEO-SMS-20260128-v2`  
**Target:** Colombia (+57) and international SMS delivery  
**Status:** Production-ready with international support

---

## 🚨 CRITICAL: SNS Configuration Checklist

**BEFORE deploying Lambda, verify these SNS settings in AWS Console:**

### 1. SNS Text Messaging Preferences

Navigate to: **AWS Console → SNS → Text messaging (SMS) → Preferences**

✅ **Monthly spend limit:** NOT $0 (set to $5-$10 for testing)  
✅ **Default message type:** Transactional  
✅ **Account spend limit:** Check current usage  
✅ **Delivery status logging:** ENABLED (100% sample rate for testing)  

**How to enable delivery status logging:**
1. Go to SNS → Text messaging (SMS) → Delivery status logging
2. Click "Edit"
3. Enable "Success sample rate": 100
4. Enable "Failure sample rate": 100
5. Select IAM role (or create new): `SNSSuccessFeedback` and `SNSFailureFeedback`
6. Save changes

### 2. Country-Specific Settings

Navigate to: **AWS Console → SNS → Text messaging (SMS) → Country-specific settings**

✅ **Colombia (+57):** NOT blocked  
✅ **Default sender ID:** (Optional, may not be supported in Colombia)  
✅ **Check origination numbers:** Not required for transactional SMS  

**Colombia SMS Notes:**
- Colombia supports international SMS via SNS
- Transactional SMS type is recommended
- Sender ID may not be displayed (carrier-dependent)
- Delivery typically takes 5-30 seconds

### 3. IAM Permissions

Verify Lambda execution role has:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

### 4. CloudWatch Logs

Verify log groups exist:
- `/aws/lambda/gemini3-sms-sender-prod` (Lambda logs)
- `/aws/sns/us-east-1/[AccountID]/DirectPublishToPhoneNumber/Failure` (SNS failures)
- `/aws/sns/us-east-1/[AccountID]/DirectPublishToPhoneNumber` (SNS success)

---

## 📋 Deployment Steps

### Step 1: Verify SNS Configuration
```powershell
# Check SNS spend limit
aws sns get-sms-attributes

# Expected output should show:
# MonthlySpendLimit: NOT "0"
# DefaultSMSType: "Transactional"
```

### Step 2: Deploy Lambda + API Gateway
```powershell
.\Gemini3_AllSensesAI\deployment\deploy-sms-backend.ps1
```

### Step 3: Test with Colombia Number
```powershell
# Test Lambda directly
aws lambda invoke `
  --function-name gemini3-sms-sender-prod `
  --payload '{"to":"+573222063010","message":"Test from AllSenses"}' `
  --cli-binary-format raw-in-base64-out `
  response.json

# Check response
cat response.json
```

### Step 4: Check CloudWatch Logs
```powershell
# Lambda logs
aws logs tail /aws/lambda/gemini3-sms-sender-prod --follow

# SNS delivery logs (wait 1-2 minutes after send)
aws logs tail /aws/sns/us-east-1/[AccountID]/DirectPublishToPhoneNumber --follow
```

---

## 🔍 Troubleshooting Guide

### Issue: SMS Not Arriving

**Step 1: Check Lambda Logs**
```powershell
aws logs tail /aws/lambda/gemini3-sms-sender-prod --since 5m
```

Look for:
- `[SMS-LAMBDA] Publishing SMS to +57******3010`
- `[SMS-LAMBDA] SMS published successfully. MessageId: abc123`

**Step 2: Check SNS Delivery Logs**
```powershell
# Find your account ID
aws sts get-caller-identity --query Account --output text

# Check SNS logs (replace [AccountID])
aws logs tail /aws/sns/us-east-1/[AccountID]/DirectPublishToPhoneNumber --since 5m
```

Look for:
- `"status": "SUCCESS"` → SMS delivered
- `"status": "FAILURE"` → Check `providerResponse` for reason

**Step 3: Common Failure Reasons**

| Error | Cause | Solution |
|-------|-------|----------|
| `Monthly spend limit exceeded` | Spend limit is $0 or reached | Increase limit in SNS preferences |
| `Invalid phone number` | Not E.164 format | Use +573222063010 format |
| `Opt out` | Number previously opted out | Remove from opt-out list in SNS |
| `Blocked destination` | Country blocked | Check country-specific settings |
| `Throttling` | Too many requests | Add retry logic or increase limits |

### Issue: "Monthly spend limit exceeded"

**Fix:**
1. Go to AWS Console → SNS → Text messaging (SMS) → Preferences
2. Click "Edit" on "Account spend limit"
3. Set to $5 or $10 (safe for testing)
4. Save changes
5. Wait 1-2 minutes
6. Retry SMS send

### Issue: "Invalid phone number"

**Fix:**
- Colombia format: `+573222063010` (country code 57 + 10-digit number)
- NOT: `3222063010`, `573222063010`, `+57-322-206-3010`
- Verify with regex: `^\+[1-9]\d{6,14}$`

### Issue: No delivery logs

**Fix:**
1. Enable delivery status logging (see SNS Configuration above)
2. Wait 2-3 minutes after enabling
3. Send test SMS
4. Check logs again after 1-2 minutes

---

## 📊 Monitoring

### Real-Time Monitoring
```powershell
# Watch Lambda invocations
aws cloudwatch get-metric-statistics `
  --namespace AWS/Lambda `
  --metric-name Invocations `
  --dimensions Name=FunctionName,Value=gemini3-sms-sender-prod `
  --start-time (Get-Date).AddMinutes(-5).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss") `
  --end-time (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss") `
  --period 60 `
  --statistics Sum

# Watch Lambda errors
aws cloudwatch get-metric-statistics `
  --namespace AWS/Lambda `
  --metric-name Errors `
  --dimensions Name=FunctionName,Value=gemini3-sms-sender-prod `
  --start-time (Get-Date).AddMinutes(-5).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss") `
  --end-time (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss") `
  --period 60 `
  --statistics Sum
```

### Cost Monitoring
```powershell
# Check SMS costs (last 7 days)
aws ce get-cost-and-usage `
  --time-period Start=(Get-Date).AddDays(-7).ToString("yyyy-MM-dd"),End=(Get-Date).ToString("yyyy-MM-dd") `
  --granularity DAILY `
  --metrics UnblendedCost `
  --filter file://sns-cost-filter.json
```

**sns-cost-filter.json:**
```json
{
  "Dimensions": {
    "Key": "SERVICE",
    "Values": ["Amazon Simple Notification Service"]
  }
}
```

---

## 🧪 Testing Checklist

### Pre-Deployment Tests
- [ ] SNS spend limit > $0
- [ ] Delivery status logging enabled
- [ ] Colombia (+57) not blocked
- [ ] IAM permissions correct

### Post-Deployment Tests
- [ ] Lambda deploys successfully
- [ ] API Gateway endpoint accessible
- [ ] Test SMS to Colombia number
- [ ] SMS arrives within 30 seconds
- [ ] Message matches preview exactly
- [ ] Delivery Proof panel updates
- [ ] CloudWatch logs show success

### Production Verification
- [ ] Real emergency contact receives SMS
- [ ] SMS content is correct
- [ ] Delivery time < 30 seconds
- [ ] No errors in CloudWatch logs
- [ ] Cost tracking enabled

---

## 📞 Emergency Contacts

**AWS Support:**
- Console: https://console.aws.amazon.com/support/
- Phone: Check your support plan

**SNS Limits:**
- Default: 1 SMS/second
- Request increase: AWS Support → Service Limit Increase

**Colombia SMS Costs:**
- Approximate: $0.02 - $0.05 per SMS
- Check current rates: https://aws.amazon.com/sns/sms-pricing/

---

## 📝 Logs to Collect for Support

If SMS delivery fails consistently:

1. **Lambda logs:**
   ```powershell
   aws logs get-log-events `
     --log-group-name /aws/lambda/gemini3-sms-sender-prod `
     --log-stream-name (latest stream) `
     --limit 50
   ```

2. **SNS delivery logs:**
   ```powershell
   aws logs get-log-events `
     --log-group-name /aws/sns/us-east-1/[AccountID]/DirectPublishToPhoneNumber `
     --log-stream-name (latest stream) `
     --limit 50
   ```

3. **SNS attributes:**
   ```powershell
   aws sns get-sms-attributes > sns-attributes.json
   ```

4. **Test payload:**
   ```json
   {
     "to": "+573222063010",
     "message": "Test message",
     "buildId": "GEMINI3-JURY-READY-VIDEO-SMS-20260128-v2"
   }
   ```

---

**Last Updated:** 2026-01-28  
**Version:** v2 (International SMS Support)
