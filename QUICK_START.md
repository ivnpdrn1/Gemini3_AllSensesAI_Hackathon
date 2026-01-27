# Gemini3_AllSensesAI - Quick Start

## 🚀 Get Running in 5 Minutes

### Step 1: Get API Key (2 minutes)

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with Google account
3. Click "Create API Key"
4. Copy the key (starts with `AIza...`)

### Step 2: Configure (1 minute)

```powershell
# Navigate to project
cd Gemini3_AllSensesAI

# Copy environment template
cp .env.example .env

# Edit .env and paste your API key
notepad .env
```

Your `.env` should look like:
```env
GOOGLE_GEMINI_API_KEY=AIzaSy...YOUR_ACTUAL_KEY
GEMINI_MODEL=gemini-1.5-pro
```

### Step 3: Run Demo (2 minutes)

```powershell
# Navigate to demo folder
cd demo

# Run deployment script
.\deploy-demo.ps1
```

The script will:
- ✅ Check Python installation
- ✅ Create virtual environment
- ✅ Install dependencies
- ✅ Start Flask backend on http://localhost:5000

### Step 4: Open Demo

1. Open `gemini-emergency-demo.html` in your browser
2. Check Runtime Health Panel (should show "LIVE" if API key is valid)
3. Click "Analyze with Gemini" to test

## What You'll See

### Runtime Health Panel

- **Gemini Client**: LIVE ✅ (or FALLBACK if API unavailable)
- **Model**: gemini-1.5-pro
- **SDK Available**: Yes
- **Mode**: LIVE
- **Safe Logging**: Enabled
- **Console Tampering**: None Detected

### Emergency Pipeline (5 Steps)

1. ✅ Identity & Emergency Contacts
2. ✅ Location Services
3. ✅ Voice/Text Capture
4. 🔄 Gemini Threat Analysis (click to run)
5. ⏳ Emergency Alerting (triggers if HIGH/CRITICAL)

### Analysis Result

Gemini returns:
- **Risk Level**: CRITICAL / HIGH / MEDIUM / LOW / NONE
- **Confidence**: 0.0 - 1.0
- **Reasoning**: Detailed explanation
- **Indicators**: Specific distress signals
- **Recommended Action**: ALERT / MONITOR / NONE
- **Response Time**: Actual API latency

## Demo Scenarios

### Test 1: High-Risk Emergency

Keep the default transcript:
```
Help me please, I don't feel safe. There's someone following me and I'm scared.
```

Expected: **HIGH** risk, **ALERT** action

### Test 2: Low-Risk Check-In

Change transcript to:
```
Just checking in, everything is fine here.
```

Expected: **NONE** or **LOW** risk, **NONE** action

### Test 3: Medium-Risk Concern

Change transcript to:
```
I'm walking alone at night and feeling uncomfortable.
```

Expected: **MEDIUM** risk, **MONITOR** action

## Troubleshooting

### "Backend not available"

**Problem**: Frontend shows "Backend not available - using mock mode"

**Solution**:
```powershell
# Make sure backend is running
cd demo
python backend.py
```

### "Gemini API not available"

**Problem**: Health panel shows "FALLBACK" mode

**Solution**:
1. Check `.env` file has correct API key
2. Verify API key is active in Google AI Studio
3. System will use keyword matching as fallback (safe)

### "Missing GOOGLE_GEMINI_API_KEY"

**Problem**: Backend fails to start

**Solution**:
```powershell
# Check .env file exists
cat .env

# Should contain:
# GOOGLE_GEMINI_API_KEY=AIza...
```

## Architecture Highlights

### Gemini as Primary Intelligence

- All emergency reasoning flows through Gemini 1.5 Pro
- Multimodal analysis (text, context, location)
- State-of-the-art natural language understanding

### Production-Grade Security

- ✅ API keys in environment variables only
- ✅ No hardcoded secrets
- ✅ No keys logged or displayed
- ✅ Secure configuration pattern

### Fail-Safe Design

- ✅ Graceful fallback if Gemini unavailable
- ✅ Keyword matching as backup
- ✅ No crashes or data loss
- ✅ Clear status indicators

### Runtime Transparency

- ✅ Real-time health monitoring
- ✅ Visible system status
- ✅ Detailed logging
- ✅ Jury-safe diagnostics

## Next Steps

### For Development

1. Review [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed setup
2. Explore [prompts/README.md](prompts/README.md) for prompt engineering
3. Check [architecture/overview.md](architecture/overview.md) for system design

### For Deployment

1. See [deployment/README.md](deployment/README.md) for AWS deployment
2. Configure CloudFormation parameters
3. Deploy Lambda functions
4. Set up API Gateway

### For Jury Demo

1. Read [demo/JURY_DEMO_GUIDE.md](demo/JURY_DEMO_GUIDE.md)
2. Practice demo scenarios
3. Understand ERNIE → Gemini parity
4. Prepare to show runtime diagnostics

## Key Files

```
Gemini3_AllSensesAI/
├── .env                          # Your API key (create from .env.example)
├── QUICK_START.md               # This file
├── SETUP_GUIDE.md               # Detailed setup instructions
├── demo/
│   ├── gemini-emergency-demo.html   # Frontend demo
│   ├── backend.py                   # Flask API server
│   ├── deploy-demo.ps1             # Deployment script
│   └── JURY_DEMO_GUIDE.md          # Jury presentation guide
├── src/
│   └── gemini/
│       └── client.py               # Gemini API client
└── prompts/
    └── gemini_reasoning_prompt.md  # Emergency detection prompt
```

## Support

- **Google AI Studio**: https://makersuite.google.com
- **Gemini API Docs**: https://ai.google.dev/docs
- **Project Issues**: Check backend logs for errors

---

**Status**: ✅ Ready for Demo  
**Gemini Integration**: ✅ Complete  
**Runtime Proof**: ✅ Implemented  
**Jury Safe**: ✅ Verified  
**Hackathon Compliant**: ✅ Confirmed
