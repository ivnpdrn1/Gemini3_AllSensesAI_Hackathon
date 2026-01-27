# Gemini Emergency Detection Demo

## Overview

This demo showcases AllSensesAI with Google Gemini 1.5 Pro as the primary intelligence layer, demonstrating real-time emergency detection with runtime diagnostics and jury-visible proof.

## Quick Start

### 1. Prerequisites

- Python 3.8+
- Google Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)

### 2. Setup

```powershell
# From Gemini3_AllSensesAI directory
cp .env.example .env
# Edit .env and add your GOOGLE_GEMINI_API_KEY

# Navigate to demo
cd demo

# Run deployment script
.\deploy-demo.ps1
```

### 3. Access

- **Backend**: http://localhost:5000
- **Frontend**: Open `gemini-emergency-demo.html` in browser

## Files

### Frontend
- `gemini-emergency-demo.html` - Complete UI with runtime health panel, 5-step pipeline, and analysis display

### Backend
- `backend.py` - Flask REST API server with Gemini integration
- `requirements.txt` - Python dependencies

### Deployment
- `deploy-demo.ps1` - Automated deployment script for Windows

### Documentation
- `JURY_DEMO_GUIDE.md` - Complete jury presentation guide
- `README.md` - This file

## API Endpoints

### GET /health

Returns runtime health status:

```json
{
  "status": "healthy",
  "gemini_available": true,
  "sdk_loaded": true,
  "model_name": "gemini-1.5-pro",
  "mode": "LIVE",
  "timestamp": 1706284800.0
}
```

### POST /analyze

Analyzes emergency situation:

**Request**:
```json
{
  "transcript": "Help me please, I'm scared",
  "location": "37.7749, -122.4194",
  "name": "Demo User",
  "contact": "+1-555-0100"
}
```

**Response**:
```json
{
  "risk_level": "HIGH",
  "confidence": 0.85,
  "reasoning": "Explicit help request with fear expression...",
  "indicators": ["explicit_help_request", "fear_expressed"],
  "recommended_action": "ALERT",
  "response_time": 1.5,
  "mode": "LIVE"
}
```

## Demo Scenarios

### High-Risk Emergency
**Input**: "Help me please, I don't feel safe. There's someone following me and I'm scared."  
**Expected**: HIGH risk, ALERT action

### Medium-Risk Concern
**Input**: "I'm walking alone at night and feeling uncomfortable."  
**Expected**: MEDIUM risk, MONITOR action

### Low-Risk Check-In
**Input**: "Just checking in, everything is fine here."  
**Expected**: NONE/LOW risk, NONE action

## Runtime Modes

### LIVE Mode
- Gemini API is available and responding
- Real AI analysis using gemini-1.5-pro
- Full multimodal reasoning

### FALLBACK Mode
- Gemini API unavailable
- Keyword matching analysis
- Safe default responses

### MOCK Mode
- Backend not running
- Frontend-only simulation
- Demo purposes only

## Troubleshooting

### Backend Won't Start

**Problem**: `python backend.py` fails

**Solution**:
```powershell
# Check Python version
python --version

# Install dependencies
pip install -r requirements.txt

# Verify .env file
cat ../.env
```

### Gemini API Errors

**Problem**: "Gemini unavailable" in logs

**Solution**:
1. Check API key in `.env` is correct
2. Verify key is active in Google AI Studio
3. System will fall back to keyword matching

### Frontend Can't Connect

**Problem**: "Backend not available" message

**Solution**:
- Ensure backend is running: `python backend.py`
- Check backend is on port 5000
- Verify CORS is enabled (it is by default)

## Architecture

### Frontend → Backend → Gemini

```
Browser (HTML/JS)
    ↓ HTTP
Flask API Server
    ↓ SDK
Google Gemini 1.5 Pro
    ↓ Response
Flask API Server
    ↓ JSON
Browser (Display)
```

### Fallback Chain

```
1. Try Gemini API
   ↓ (if fails)
2. Use keyword matching
   ↓ (if fails)
3. Return safe default (MEDIUM risk)
```

## Security

- ✅ API keys in environment variables only
- ✅ No hardcoded secrets
- ✅ No keys in logs or UI
- ✅ CORS enabled for localhost only
- ✅ Input validation and sanitization

## Development

### Running Backend Manually

```powershell
# Activate virtual environment
../.venv/Scripts/Activate.ps1

# Set environment
$env:FLASK_DEBUG = "True"
$env:PORT = "5000"

# Run server
python backend.py
```

### Testing API

```powershell
# Health check
curl http://localhost:5000/health

# Analysis
curl -X POST http://localhost:5000/analyze `
  -H "Content-Type: application/json" `
  -d '{"transcript":"Help me","location":"37.7749,-122.4194","name":"Test","contact":"+1-555-0100"}'
```

## Deployment

### Local Development
Use `deploy-demo.ps1` script (recommended)

### Production
See `../deployment/README.md` for AWS Lambda deployment

## Support

- **Google AI Studio**: https://makersuite.google.com
- **Gemini API Docs**: https://ai.google.dev/docs
- **Flask Docs**: https://flask.palletsprojects.com
- **Project Setup**: See `../SETUP_GUIDE.md`

---

**Status**: ✅ Ready for Demo  
**Gemini Integration**: ✅ Complete  
**Runtime Proof**: ✅ Implemented
