# AllSensesAI - Gemini 3 Edition

**AI-Powered Emergency Detection and Response System**

## Overview

AllSensesAI is a real-time emergency detection system that uses **Google Gemini 3** as its primary intelligence layer to analyze multimodal inputs (text, audio, images) and detect distress situations requiring emergency response.

## Architecture Philosophy

This system is built on a **Gemini-First Architecture** where:

- **Gemini 3** = Intelligence, reasoning, multimodal understanding, risk assessment
- **KIRO** = Decision orchestration, scoring logic, workflow management
- **AWS** = Execution, messaging, persistence, scaling

**CRITICAL**: Gemini 3 is the irreplaceable core intelligence engine. The system cannot function without it.

## Key Capabilities

1. **Multimodal Distress Detection**
   - Text analysis (transcripts, messages)
   - Audio analysis (voice patterns, background sounds)
   - Image analysis (visual context, environmental cues)

2. **Contextual Risk Assessment**
   - Gemini 3 provides nuanced understanding of context
   - Explains reasoning behind risk classifications
   - Adapts to cultural and situational variations

3. **Event-Driven Response**
   - Automated alert generation
   - Emergency service notification
   - Trusted contact messaging

## Technology Stack

- **AI/ML**: Google Gemini 3 (via Vertex AI or AI Studio)
- **Orchestration**: KIRO decision engine
- **Cloud**: AWS (Lambda, SNS, S3, DynamoDB)
- **Frontend**: Progressive Web App (HTML5, JavaScript)

## Project Structure

```
Gemini3_AllSensesAI/
├── README.md                    # This file
├── architecture/                # Architecture documentation
├── prompts/                     # Gemini 3 prompt engineering
├── src/                         # Source code
│   ├── gemini/                  # Gemini 3 integration
│   ├── kiro/                    # KIRO orchestration
│   ├── aws/                     # AWS services integration
│   └── utils/                   # Shared utilities
├── compliance/                  # Hackathon compliance notes
├── tests/                       # Test suites
└── deployment/                  # Deployment scripts
```

## Getting Started

### Option 1: CloudFront Deployment (Recommended for Jury Demo)

**One-command deployment to AWS:**

```powershell
cd Gemini3_AllSensesAI
.\deployment\deploy-gemini-runtime.ps1
```

**Time**: 5-7 minutes  
**Output**: CloudFront HTTPS URL (GPS-enabled)

**Prerequisites:**
- AWS CLI configured
- Python 3.11+
- Gemini API key in `.env` file

**Documentation:**
- [DEPLOY_GEMINI_RUNTIME.md](DEPLOY_GEMINI_RUNTIME.md) - Complete deployment guide
- [JURY_DEMO_CLOUDFRONT.md](JURY_DEMO_CLOUDFRONT.md) - Quick reference for jury
- [TROUBLESHOOTING_GEMINI_RUNTIME.md](TROUBLESHOOTING_GEMINI_RUNTIME.md) - Common issues

---

### Option 2: Local Demo

1. **Get Gemini API Key**
   - Visit [Google AI Studio](https://aistudio.google.com/app/apikey)
   - Create a new API key

2. **Configure Environment**
   ```bash
   # Create .env file in project root
   echo "GOOGLE_GEMINI_API_KEY=your_api_key_here" > .env
   echo "GEMINI_MODEL=gemini-1.5-pro" >> .env
   ```

3. **Install Dependencies**
   ```bash
   pip install -r demo/requirements.txt
   ```

4. **Run Local Demo**
   ```bash
   python demo/backend.py
   # Open demo/gemini-emergency-demo.html in browser
   ```

---

### Documentation

- [architecture/overview.md](architecture/overview.md) - System design
- [prompts/README.md](prompts/README.md) - Gemini prompt documentation
- [DEPLOY_GEMINI_RUNTIME.md](DEPLOY_GEMINI_RUNTIME.md) - CloudFront deployment
- [JURY_DEMO_CLOUDFRONT.md](JURY_DEMO_CLOUDFRONT.md) - Jury quick reference

## Compliance

This project was created from scratch for the Google Gemini 3 Hackathon. All code, prompts, and logic are original work created during the hackathon period. No code from previous systems (ERNIE, Baidu, or other platforms) has been copied or reused.

See [compliance/gemini_hackathon_notes.md](compliance/gemini_hackathon_notes.md) for detailed compliance documentation.

## License

Copyright 2026 - AllSensesAI Gemini 3 Edition
