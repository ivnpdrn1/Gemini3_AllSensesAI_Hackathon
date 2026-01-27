# Gemini CloudFront - Quick Start Guide

Get from zero to jury-ready demo in 20 minutes.

---

## ⚡ TL;DR

```powershell
# 1. Get API key from Google AI Studio
# 2. Add to .env file
# 3. Run deployment
cd Gemini3_AllSensesAI
.\deployment\deploy-gemini-runtime.ps1

# 4. Open CloudFront URL in browser
# 5. Test with HIGH risk scenario
```

**Time**: 20 minutes  
**Output**: CloudFront HTTPS URL

---

## 📋 Prerequisites (5 minutes)

### 1. AWS CLI
```powershell
# Check if installed
aws --version

# If not installed, download from:
# https://aws.amazon.com/cli/

# Configure
aws configure
```

### 2. Python 3.11+
```powershell
# Check version
python --version

# If not installed, download from:
# https://www.python.org/downloads/
```

### 3. Gemini API Key
1. Visit: https://aistudio.google.com/app/apikey
2. Click "Create API Key"
3. Copy the key

### 4. Create .env File
```powershell
cd Gemini3_AllSensesAI

# Create .env file
@"
GOOGLE_GEMINI_API_KEY=your_api_key_here
GEMINI_MODEL=gemini-1.5-pro
"@ | Out-File -FilePath .env -Encoding UTF8
```

---

## 🚀 Deploy (7 minutes)

```powershell
# From project root
cd Gemini3_AllSensesAI

# Run deployment script
.\deployment\deploy-gemini-runtime.ps1
```

**What happens:**
1. Checks prerequisites
2. Stores API key in AWS (encrypted)
3. Packages Lambda function
4. Deploys CloudFormation stack
5. Updates Lambda code
6. Deploys UI to S3
7. Invalidates CloudFront cache

**Output:**
```
========================================
DEPLOYMENT COMPLETE
========================================

Jury Demo URL (HTTPS, GPS-enabled):
  https://d1234567890.cloudfront.net

Lambda Function URL:
  https://abcdefg.lambda-url.us-east-1.on.aws/
```

**Copy the CloudFront URL!**

---

## ✅ Validate (3 minutes)

```powershell
# Run validation script
.\deployment\validate-gemini-runtime.ps1
```

**Expected output:**
```
[1/4] Testing Lambda health endpoint... OK
[2/4] Testing Lambda analysis endpoint... OK
[3/4] Testing CloudFront UI... OK
[4/4] Validating HTTPS and CORS... OK

========================================
VALIDATION COMPLETE
========================================
```

---

## 🎬 Demo Prep (5 minutes)

### 1. Open CloudFront URL
Open the CloudFront URL from deployment output in your browser.

### 2. Check Runtime Health
Verify the health panel shows:
- **Gemini Client**: LIVE (green)
- **Model**: gemini-1.5-pro
- **Mode**: LIVE
- **Backend**: Lambda
- **Deployment**: CloudFront

### 3. Prepare Test Transcript
Copy this HIGH risk scenario:
```
Help me please, I don't feel safe. There's someone following me and I'm scared.
```

### 4. Open Browser Console
Press F12 to open developer console for logs.

---

## 🎯 5-Minute Demo

### 1. Introduction (30 seconds)
- Show CloudFront URL (HTTPS in address bar)
- Point out "CloudFront + Lambda" in subtitle
- Mention architectural parity with ERNIE

### 2. Runtime Health (1 minute)
- Walk through health panel
- Explain LIVE vs FALLBACK modes
- Show model name (gemini-1.5-pro)
- Emphasize runtime proof (not mocked)

### 3. Pipeline Overview (1 minute)
Walk through 5 steps:
1. Identity & Emergency Contacts
2. Location Services (GPS)
3. Voice/Text Capture
4. Gemini Threat Analysis
5. Emergency Alerting

### 4. Live Analysis (2 minutes)
- Paste HIGH risk transcript
- Click "Analyze with Gemini"
- Show result:
  - Risk Level: HIGH
  - Confidence: 85%
  - Mode: LIVE
  - Indicators: help_request, fear, stalking
  - Reasoning: Detailed explanation

### 5. Console Logs (30 seconds)
- Scroll to console log panel
- Show audit trail:
  ```
  [12:34:56] System initializing...
  [12:34:57] Gemini SDK detected and initialized
  [12:35:00] Analysis complete: HIGH (confidence: 0.85)
  ```

---

## 💬 Key Talking Points

1. **Architecture Parity**
   > "This demonstrates complete architectural parity between ERNIE and Gemini. Same 5-step pipeline, same safety guarantees, only the AI provider changed."

2. **Runtime Proof**
   > "The Runtime Health panel provides proof that Gemini is actually running, not mocked. If unavailable, it clearly shows FALLBACK mode."

3. **Production Deployment**
   > "Deployed on AWS CloudFront + Lambda for production-grade reliability. HTTPS enables GPS access for location services."

4. **Gemini Intelligence**
   > "Gemini 1.5 Pro provides the intelligence layer. All emergency reasoning flows through Gemini's multimodal understanding."

5. **Safety Guarantees**
   > "System fails safely to keyword matching if Gemini is unavailable. All state transitions are logged for audit."

---

## 🔧 Quick Troubleshooting

### Runtime Health Shows FALLBACK
```powershell
# Check Lambda logs
aws logs tail /aws/lambda/allsensesai-gemini-analysis --follow

# Verify API key
aws ssm get-parameter --name "/allsensesai/gemini/api-key" --with-decryption
```

### CloudFront Shows Old Content
```powershell
# Get distribution ID
$info = Get-Content deployment/deployment-info.json | ConvertFrom-Json

# Invalidate cache
aws cloudfront create-invalidation --distribution-id $info.distributionId --paths "/*"

# Wait 1-2 minutes, then hard refresh browser (Ctrl+Shift+R)
```

### Lambda Returns 500 Error
```powershell
# Check logs
aws logs tail /aws/lambda/allsensesai-gemini-analysis --follow

# Redeploy if needed
.\deployment\deploy-gemini-runtime.ps1
```

---

## 📚 Documentation

- **DEPLOY_GEMINI_RUNTIME.md** - Complete deployment guide
- **JURY_DEMO_CLOUDFRONT.md** - Detailed demo reference
- **TROUBLESHOOTING_GEMINI_RUNTIME.md** - Common issues
- **DEPLOYMENT_CHECKLIST.md** - Step-by-step checklist

---

## 📊 Demo Scenarios

### HIGH RISK (Stalking)
```
Help me please, I don't feel safe. There's someone following me and I'm scared.
```
**Expected**: Risk Level HIGH, Confidence 80-90%, Action ALERT

### MEDIUM RISK (Uncomfortable)
```
I'm feeling uncomfortable in this situation. Not sure what to do.
```
**Expected**: Risk Level MEDIUM, Confidence 60-70%, Action MONITOR

### LOW RISK (Check-in)
```
Everything is fine, just checking in. No issues here.
```
**Expected**: Risk Level LOW/NONE, Confidence 30-40%, Action NONE

---

## ⏱️ Timeline

| Phase | Time | Action |
|-------|------|--------|
| Prerequisites | 5 min | AWS CLI, Python, API key, .env |
| Deployment | 7 min | Run deploy script |
| Validation | 3 min | Run validation script |
| Demo Prep | 5 min | Open URL, check health, prepare |
| **Total** | **20 min** | **Ready for demo** |
| Demo | 5 min | Live presentation |
| Q&A | 5-10 min | Answer questions |

---

## ✅ Success Checklist

Before demo:
- [ ] CloudFront URL accessible
- [ ] Runtime Health shows LIVE
- [ ] HIGH risk scenario tested
- [ ] Console logs visible
- [ ] Browser console open (F12)
- [ ] Troubleshooting commands ready

---

## 🎉 You're Ready!

**CloudFront URL**: (from deployment output)  
**Demo Duration**: 5 minutes  
**Backup Plan**: Fallback mode if Gemini unavailable  
**Documentation**: All guides in `Gemini3_AllSensesAI/`

**Good luck with your demo! 🚀**

---

## 📞 Need Help?

```powershell
# View deployment info
Get-Content deployment/deployment-info.json

# View logs
aws logs tail /aws/lambda/allsensesai-gemini-analysis --follow

# Run validation
.\deployment\validate-gemini-runtime.ps1
```

**Documentation**: See `TROUBLESHOOTING_GEMINI_RUNTIME.md`
