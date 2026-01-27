# Gemini Emergency Detection - Jury Demo Guide

## Overview

This demo showcases **AllSensesAI with Google Gemini 1.5 Pro** as the primary intelligence layer, demonstrating architectural parity with the ERNIE implementation while using Google's state-of-the-art multimodal AI.

## Quick Start

### 1. Prerequisites

- Python 3.8+
- Google Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)

### 2. Setup (5 minutes)

```powershell
# Navigate to project
cd Gemini3_AllSensesAI

# Configure environment
cp .env.example .env
# Edit .env and add your GOOGLE_GEMINI_API_KEY

# Deploy demo
cd demo
.\deploy-demo.ps1
```

### 3. Access Demo

1. **Backend**: http://localhost:5000
2. **Frontend**: Open `gemini-emergency-demo.html` in browser

## Demo Flow

### Step 1: Runtime Health Check

The demo displays real-time system status:

- **Gemini Client**: LIVE (if API key valid) or FALLBACK
- **Model**: gemini-1.5-pro
- **SDK Available**: Yes/No
- **Mode**: LIVE/FALLBACK/MOCK
- **Safe Logging**: Enabled (no API keys logged)
- **Console Tampering**: None Detected

### Step 2: Emergency Pipeline (5 Steps)

1. **Identity & Emergency Contacts** ✓
   - Pre-configured demo user
   - Emergency contact: +1-555-0100

2. **Location Services** ✓
   - Demo location: San Francisco (37.7749, -122.4194)
   - GPS coordinates ready

3. **Voice/Text Capture** ✓
   - Sample transcript: "Help me please, I don't feel safe. There's someone following me and I'm scared."
   - Editable for different scenarios

4. **Gemini Threat Analysis** (Active)
   - Click "Analyze with Gemini"
   - Gemini 1.5 Pro analyzes situation
   - Returns risk assessment with reasoning

5. **Emergency Alerting** (Conditional)
   - Triggers if risk level is HIGH or CRITICAL
   - Would send alerts to 911 + emergency contacts

### Step 3: Analysis Results

Gemini returns structured assessment:

- **Risk Level**: CRITICAL / HIGH / MEDIUM / LOW / NONE
- **Confidence**: 0.0 - 1.0 (percentage certainty)
- **Mode**: LIVE (real Gemini) or FALLBACK (keyword matching)
- **Response Time**: Actual API latency
- **Reasoning**: Detailed explanation of assessment
- **Indicators**: Specific distress signals detected
- **Recommended Action**: ALERT / MONITOR / NONE

## Architecture Parity: ERNIE → Gemini

| Component | ERNIE Implementation | Gemini Implementation |
|-----------|---------------------|----------------------|
| **AI Provider** | Baidu ERNIE | Google Gemini |
| **Model** | ERNIE-Bot | gemini-1.5-pro |
| **API Source** | Baidu Cloud | Google AI Studio |
| **Pipeline Steps** | 5 steps | 5 steps (identical) |
| **Configuration** | Environment-based | Environment-based |
| **Security** | No hardcoded keys | No hardcoded keys |
| **Fallback** | Keyword matching | Keyword matching |
| **Runtime Diagnostics** | UI health panel | UI health panel |
| **Logging** | Safe (no secrets) | Safe (no secrets) |

**Key Point**: The same 5-step pipeline works identically with both providers. Gemini replaces ERNIE as the intelligence layer while preserving all safety guarantees.

## Runtime Guarantees

### 1. Explicit Runtime Detection

- System checks if Gemini SDK is available
- Displays status in UI health panel
- Logs initialization success/failure

### 2. Fallback Handling

If Gemini API is unavailable:
- System does NOT crash
- Falls back to keyword matching
- Logs fallback reason
- Displays "FALLBACK" mode in UI
- Returns safe default response (MEDIUM risk)

### 3. Jury-Visible Diagnostics

All runtime information visible in UI:
- Gemini client status (LIVE/FALLBACK)
- Model name (gemini-1.5-pro)
- SDK availability (Yes/No)
- Current mode (LIVE/FALLBACK/MOCK)
- Console logs with timestamps

### 4. No Secrets Exposed

- API keys loaded from environment only
- Never logged to console
- Never displayed in UI
- Never sent to frontend

## Demo Scenarios

### Scenario 1: High-Risk Emergency

**Transcript**: "Help me please, I don't feel safe. There's someone following me and I'm scared."

**Expected Result**:
- Risk Level: HIGH
- Confidence: 0.85+
- Indicators: explicit_help_request, fear_expressed, stalking_concern
- Action: ALERT

### Scenario 2: Medium-Risk Concern

**Transcript**: "I'm walking alone at night and feeling a bit uncomfortable."

**Expected Result**:
- Risk Level: MEDIUM
- Confidence: 0.50-0.70
- Indicators: safety_concern, environmental_risk
- Action: MONITOR

### Scenario 3: Low-Risk Situation

**Transcript**: "Just checking in, everything is fine here."

**Expected Result**:
- Risk Level: NONE or LOW
- Confidence: 0.20-0.40
- Indicators: no_distress_signals
- Action: NONE

## Troubleshooting

### Backend Not Starting

**Problem**: `python backend.py` fails

**Solution**:
```powershell
# Check Python version
python --version  # Should be 3.8+

# Install dependencies
pip install -r requirements.txt

# Check .env file
cat ../.env  # Should contain GOOGLE_GEMINI_API_KEY
```

### Gemini API Errors

**Problem**: "Gemini unavailable" in logs

**Solution**:
1. Verify API key in `.env` is correct
2. Check API key is active in [Google AI Studio](https://makersuite.google.com/app/apikey)
3. Ensure no rate limits exceeded
4. System will fall back to keyword matching automatically

### CORS Errors

**Problem**: Frontend can't connect to backend

**Solution**:
- Backend includes CORS headers
- Open HTML file directly (not via file:// if possible)
- Or use simple HTTP server: `python -m http.server 8080`

## Jury Presentation Points

### 1. Gemini as Primary Intelligence

"This system uses **Google Gemini 1.5 Pro** as the primary and irreplaceable intelligence layer. All emergency detection reasoning flows through Gemini's state-of-the-art multimodal AI."

### 2. Production-Grade Architecture

"The architecture mirrors industry best practices with environment-based configuration, secure API key handling, and comprehensive error handling with fallback mechanisms."

### 3. Runtime Transparency

"All system status is visible in real-time through the UI health panel. Judges can see exactly whether Gemini is live, what mode the system is in, and how the analysis is performed."

### 4. Safety Guarantees

"The system fails safely. If Gemini is unavailable, it falls back to keyword matching and logs the reason. No crash, no data loss, no security breach."

### 5. ERNIE Parity

"This demonstrates architectural parity with our ERNIE implementation. The same 5-step pipeline works identically with both providers, proving the modularity and flexibility of our design."

## Technical Specifications

- **Frontend**: Vanilla JavaScript, HTML5, CSS3
- **Backend**: Python 3.8+, Flask, google-generativeai SDK
- **Model**: gemini-1.5-pro (Google AI Studio)
- **Security**: Environment-based configuration, no hardcoded secrets
- **Fallback**: Keyword matching when Gemini unavailable
- **Logging**: Structured, timestamped, jury-safe (no secrets)
- **Response Time**: ~1-3 seconds for Gemini API calls

## Files Structure

```
demo/
├── gemini-emergency-demo.html    # Frontend UI
├── backend.py                    # Flask API server
├── requirements.txt              # Python dependencies
├── deploy-demo.ps1              # Deployment script
└── JURY_DEMO_GUIDE.md           # This file
```

## Support

- **Google AI Studio**: https://makersuite.google.com
- **Gemini API Docs**: https://ai.google.dev/docs
- **Project Setup**: See `../SETUP_GUIDE.md`

---

**Demo Ready**: ✅  
**Gemini Integration**: ✅  
**Runtime Proof**: ✅  
**Jury Safe**: ✅  
**Hackathon Compliant**: ✅
