# Quick Start: Colombia SMS Deployment

**Build:** `GEMINI3-JURY-READY-VIDEO-SMS-20260128-v2`  
**Goal:** Deploy real SMS delivery for Colombia +57 in 5 minutes

---

## ⚡ 3-Step Deployment

### Step 1: Check SNS Configuration (30 seconds)

```powershell
.\Gemini3_AllSensesAI\deployment\check-sns-config.ps1
```

**If it fails:**
1. Go to AWS Console → SNS → Text messaging (SMS) → Preferences
2. Click "Edit" on "Account spend limit"
3. Set to $5 or $10
4. Save and wait 1 minute
5. Run check script again

### Step 2: Deploy Everything (3-5 minutes)

```powershell
.\Gemini3_AllSensesAI\deployment\deploy-sms-backend.ps1
```

This will:
- ✅ Check SNS config (fail-fast if issues)
- ✅ Build HTML with SMS integration
- ✅ Deploy Lambda + API Gateway
- ✅ Update HTML with real API URL
- ✅ Upload to S3
- ✅ Create CloudFront invalidation
- ✅ Wait for propagation

### Step 3: Test with Colombia Number (1 minute)

```powershell
.\Gemini3_AllSensesAI\verify-colombia-sms.ps1
```

Then manually:
1. Open: https://dfc8ght8abwqc.cloudfront.net
2. Hard refresh: Ctrl+Shift+R
3. Complete Step 1 with: `+573222063010`
4. Click "Send Test SMS"
5. Check phone for SMS (arrives in 5-30 seconds)

---

## ✅ Success Criteria

You're done when:
- ✅ Build ID shows `v2` in UI
- ✅ SMS arrives at Colombia phone
- ✅ Message matches preview exactly
- ✅ Delivery Proof shows SENT status

---

## 🚨 Common Issues

### Issue: "Monthly spend limit exceeded"
**Fix:** Set SNS spend limit to $5 in AWS Console (see Step 1)

### Issue: SMS not arriving
**Check:**
```powershell
# Lambda logs
aws logs tail /aws/lambda/gemini3-sms-sender-prod --follow

# SNS logs (wait 1-2 minutes after send)
$accountId = aws sts get-caller-identity --query Account --output text
aws logs tail /aws/sns/us-east-1/$accountId/DirectPublishToPhoneNumber --follow
```

### Issue: "SAM CLI not found"
**Fix:** Install AWS SAM CLI
- Windows: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
- Or use Chocolatey: `choco install aws-sam-cli`

---

## 📚 Full Documentation

- **Troubleshooting:** `Gemini3_AllSensesAI/SMS_DELIVERY_RUNBOOK.md`
- **Implementation:** `Gemini3_AllSensesAI/SMS_DELIVERY_COLOMBIA_COMPLETE.md`
- **Canonical Logic:** `Gemini3_AllSensesAI/ChatGPT_KIRO_INSTRUCTIONS_GEMINI_PARITY.md`

---

**Time to Deploy:** 5 minutes  
**Time to Test:** 1 minute  
**Total:** 6 minutes from zero to working Colombia SMS ✅

