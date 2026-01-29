# SMS Backend Quick Start Guide

**Build ID:** `GEMINI3-JURY-READY-VIDEO-SMS-20260128-v1`

---

## 🚀 Quick Deployment (5 minutes)

### Prerequisites Check
```powershell
# Check AWS CLI
aws --version

# Check SAM CLI
sam --version

# Check Python
python --version
```

**Missing SAM CLI?**
```powershell
choco install aws-sam-cli
```

### Deploy Everything
```powershell
# Single command deploys backend + frontend
.\Gemini3_AllSensesAI\deployment\deploy-sms-backend.ps1
```

**Wait 2-3 minutes for CloudFront propagation**

### Verify Deployment
```powershell
.\Gemini3_AllSensesAI\verify-sms-backend.ps1
```

---

## 📱 Quick Test (2 minutes)

### Test 1: Manual SMS
1. Open: https://dfc8ght8abwqc.cloudfront.net
2. Hard refresh: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
3. Check Build ID: `GEMINI3-JURY-READY-VIDEO-SMS-20260128-v1`
4. Step 1: Enter your name and phone (`+1234567890`)
5. Click "Complete Step 1"
6. Scroll to Step 5
7. Click "Send Test SMS"
8. Check your phone

### Test 2: Auto-Trigger SMS
1. Complete Steps 1 & 2
2. Start voice detection (Step 3)
3. Say "help" or "emergency"
4. Wait for Step 4 analysis
5. If HIGH/CRITICAL risk, SMS auto-sends
6. Check Delivery Proof panel
7. Check your phone

---

## 🔍 Troubleshooting

### SMS Not Sending?

**Check 1: Phone Number Format**
- Must be E.164: `+1234567890`
- NOT: `1234567890`, `+1-234-567-890`

**Check 2: AWS SNS Sandbox**
- New AWS accounts are in sandbox mode
- Can only send to verified numbers
- Request production access: AWS Console → SNS → Text messaging (SMS) → Sandbox destination phone numbers

**Check 3: Lambda Logs**
```powershell
aws logs tail /aws/lambda/gemini3-sms-sender-prod --follow
```

**Check 4: Browser Console**
- Open DevTools (F12)
- Look for `[SMS][ERROR]` logs

### CloudFront Not Updating?

```powershell
# Check invalidation status
aws cloudfront list-invalidations --distribution-id E2NIUI2KOXAO0Q

# Hard refresh browser
# Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
```

### API URL Not Found?

```powershell
# Get API URL from stack
aws cloudformation describe-stacks `
  --stack-name gemini3-sms-backend `
  --query "Stacks[0].Outputs[?OutputKey=='SmsApiUrl'].OutputValue" `
  --output text
```

---

## 📊 Monitoring

### Lambda Metrics
```powershell
# View recent invocations
aws cloudwatch get-metric-statistics `
  --namespace AWS/Lambda `
  --metric-name Invocations `
  --dimensions Name=FunctionName,Value=gemini3-sms-sender-prod `
  --start-time (Get-Date).AddHours(-1).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss") `
  --end-time (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss") `
  --period 300 `
  --statistics Sum
```

### SMS Costs
```powershell
# View SNS costs (last 7 days)
aws ce get-cost-and-usage `
  --time-period Start=(Get-Date).AddDays(-7).ToString("yyyy-MM-dd"),End=(Get-Date).ToString("yyyy-MM-dd") `
  --granularity DAILY `
  --metrics UnblendedCost `
  --filter file://sns-filter.json
```

---

## 🎯 Acceptance Checklist

- [ ] Build ID visible: `GEMINI3-JURY-READY-VIDEO-SMS-20260128-v1`
- [ ] SMS Delivery Proof panel visible in Step 5
- [ ] "Send Test SMS" button appears after Step 1
- [ ] Manual SMS sends successfully
- [ ] SMS content matches preview exactly
- [ ] Auto-trigger works on HIGH/CRITICAL risk
- [ ] Delivery status updates in real-time
- [ ] Phone number validation works
- [ ] All baseline features still work (no regressions)

---

## 📞 Support

**Documentation:**
- Full implementation: `SMS_DELIVERY_IMPLEMENTATION_COMPLETE.md`
- Architecture details: `Gemini3_AllSensesAI/ChatGPT_KIRO_INSTRUCTIONS_GEMINI_PARITY.md`

**AWS Resources:**
- Stack: `gemini3-sms-backend`
- Function: `gemini3-sms-sender-prod`
- API: Check CloudFormation outputs

**Common Issues:**
- SNS Sandbox: Request production access
- E.164 Format: Use `+[country][number]`
- CloudFront Cache: Wait 2-3 minutes, hard refresh

---

**Last Updated:** 2026-01-28  
**Status:** Ready for deployment
