# Gemini CloudFront Demo - Jury Quick Reference

## 🎯 One-Command Deployment

```powershell
cd Gemini3_AllSensesAI
.\deployment\deploy-gemini-runtime.ps1
```

**Time**: 5-7 minutes  
**Output**: CloudFront HTTPS URL for jury demo

---

## 📋 Pre-Demo Checklist

- [ ] API key in `.env` file
- [ ] AWS CLI configured
- [ ] Python 3.11+ installed
- [ ] Deployment completed successfully
- [ ] CloudFront URL accessible
- [ ] Runtime Health shows LIVE status

---

## 🎬 5-Minute Demo Flow

### 1. Open CloudFront URL (30 seconds)
- Show HTTPS in address bar (GPS-enabled)
- Point out "CloudFront + Lambda" in subtitle

### 2. Runtime Health Panel (1 minute)
- **Gemini Client**: LIVE (green) or FALLBACK (yellow)
- **Model**: gemini-1.5-pro
- **Mode**: LIVE or FALLBACK
- **Backend**: Lambda
- **Deployment**: CloudFront

**Talking Point**: "This panel provides runtime proof that Gemini is actually running, not mocked."

### 3. Pipeline Overview (1 minute)
Walk through 5 steps:
1. **Identity**: User info + emergency contacts
2. **Location**: GPS coordinates (HTTPS required)
3. **Voice**: Transcript capture
4. **Gemini Analysis**: AI threat detection
5. **Alerting**: Emergency response

**Talking Point**: "Same 5-step pipeline as ERNIE - architectural parity."

### 4. Live Analysis (2 minutes)

**HIGH RISK Scenario:**
```
Help me please, I don't feel safe. There's someone following me and I'm scared.
```

Click "Analyze with Gemini" → Show result:
- Risk Level: HIGH
- Confidence: 85%
- Mode: LIVE (proves real Gemini call)
- Response Time: ~2s
- Reasoning: Detailed explanation
- Indicators: explicit_help_request, fear_expressed, stalking_concern

**Talking Point**: "Gemini detected multiple distress signals and recommended immediate alert."

### 5. Console Logs (30 seconds)
Scroll to console log panel:
```
[12:34:56] System initializing...
[12:34:57] Gemini SDK detected and initialized
[12:34:58] Model: gemini-1.5-pro
[12:35:00] Analysis complete: HIGH (confidence: 0.85)
```

**Talking Point**: "Console logs provide audit trail for jury verification."

---

## 🎤 Key Talking Points

### Architecture Parity
> "This system demonstrates complete architectural parity between ERNIE and Gemini. The same 5-step pipeline, same safety guarantees, same fallback mechanisms - only the AI provider changed."

### Runtime Proof
> "The Runtime Health panel shows live status. If Gemini is unavailable, the system fails safely to keyword matching and clearly displays FALLBACK mode."

### Production Deployment
> "Deployed on AWS CloudFront + Lambda for production-grade reliability. HTTPS enables GPS access for location services."

### Gemini Integration
> "Gemini 1.5 Pro provides the intelligence layer. All emergency reasoning flows through Gemini's multimodal understanding."

---

## 📊 Demo Scenarios

### Scenario 1: HIGH RISK (Stalking)
**Transcript:**
```
Help me please, I don't feel safe. There's someone following me and I'm scared.
```

**Expected Result:**
- Risk Level: HIGH
- Confidence: 80-90%
- Action: ALERT
- Indicators: help_request, fear, stalking

---

### Scenario 2: MEDIUM RISK (Uncomfortable)
**Transcript:**
```
I'm feeling uncomfortable in this situation. Not sure what to do.
```

**Expected Result:**
- Risk Level: MEDIUM
- Confidence: 60-70%
- Action: MONITOR
- Indicators: discomfort, uncertainty

---

### Scenario 3: LOW RISK (Check-in)
**Transcript:**
```
Everything is fine, just checking in. No issues here.
```

**Expected Result:**
- Risk Level: LOW or NONE
- Confidence: 30-40%
- Action: NONE
- Indicators: no_indicators

---

## 🔧 Quick Troubleshooting

### Issue: CloudFront shows old content
**Solution:**
```powershell
aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/*"
```
Wait 1-2 minutes.

---

### Issue: Runtime Health shows FALLBACK
**Possible Causes:**
1. API key invalid
2. Gemini quota exceeded
3. Network issue

**Check Lambda logs:**
```powershell
aws logs tail /aws/lambda/allsensesai-gemini-analysis --follow
```

---

### Issue: Lambda returns 500 error
**Solution:**
```powershell
# Verify API key
aws ssm get-parameter --name "/allsensesai/gemini/api-key" --with-decryption

# Update if needed
aws ssm put-parameter --name "/allsensesai/gemini/api-key" --value "NEW_KEY" --type "SecureString" --overwrite
```

---

## 📱 Browser Console Commands

Open browser console (F12) and run:

```javascript
// Check runtime state
console.log(RUNTIME);

// Manual health check
fetch('{{LAMBDA_URL}}/health').then(r => r.json()).then(console.log);

// Manual analysis
fetch('{{LAMBDA_URL}}/analyze', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({
        transcript: 'Help me!',
        location: '37.7749, -122.4194',
        name: 'Test',
        contact: '+1-555-0100'
    })
}).then(r => r.json()).then(console.log);
```

---

## 🎯 Success Criteria

✅ CloudFront URL accessible via HTTPS  
✅ Runtime Health panel shows LIVE status  
✅ Gemini analysis returns structured JSON  
✅ HIGH risk scenarios trigger alerts  
✅ Console logs show audit trail  
✅ Fallback mode works if Gemini unavailable  

---

## 📞 Emergency Contacts

**Deployment Info:**
```powershell
cat deployment/deployment-info.json
```

**Validation:**
```powershell
.\deployment\validate-gemini-runtime.ps1
```

**Logs:**
```powershell
aws logs tail /aws/lambda/allsensesai-gemini-analysis --follow
```

---

## 🏆 Jury Presentation Tips

1. **Start with Architecture**: Show CloudFront + Lambda diagram
2. **Emphasize Parity**: Compare side-by-side with ERNIE
3. **Live Demo**: Use HIGH risk scenario first
4. **Show Fallback**: Explain safety guarantees
5. **Console Proof**: Scroll through logs for verification
6. **Q&A Ready**: Have troubleshooting commands ready

---

## 📚 Additional Resources

- **Full Deployment Guide**: `DEPLOY_GEMINI_RUNTIME.md`
- **Troubleshooting**: `TROUBLESHOOTING_GEMINI_RUNTIME.md`
- **Architecture**: `architecture/overview.md`
- **Validation**: `DEPLOYMENT_VALIDATION_CHECKLIST.md`

---

## ⏱️ Timeline

- **Deployment**: 5-7 minutes
- **Validation**: 2-3 minutes
- **Demo Prep**: 5 minutes
- **Live Demo**: 5 minutes
- **Q&A**: 5-10 minutes

**Total**: 20-30 minutes from start to finish
