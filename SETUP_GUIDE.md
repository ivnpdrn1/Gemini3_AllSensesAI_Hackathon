# AllSensesAI - Gemini Edition Setup Guide

## Quick Start

### 1. Get Your Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the API key (starts with `AIza...`)

### 2. Configure Environment

Create a `.env` file in the project root:

```bash
cd Gemini3_AllSensesAI
cp .env.example .env
```

Edit `.env` and add your API key:

```env
GOOGLE_GEMINI_API_KEY=AIzaSy...YOUR_ACTUAL_KEY_HERE
GEMINI_MODEL=gemini-1.5-pro
```

**IMPORTANT**: Never commit `.env` to git. It's already in `.gitignore`.

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Test the Integration

Create a test script `test_gemini.py`:

```python
from src.gemini.client import GeminiClient

# Initialize client (reads from .env)
client = GeminiClient()

# Test health check
if client.health_check():
    print("✓ Gemini API is accessible")
else:
    print("✗ Gemini API connection failed")

# Test emergency analysis
input_data = {
    "modalities": [
        {"type": "text", "content": "Help me please, I need assistance"}
    ],
    "context": {}
}

prompt = "Analyze this emergency situation and respond with JSON containing risk_level, confidence, reasoning, indicators, and recommended_action."

result = client.analyze_emergency(input_data, prompt)
print(f"\nRisk Level: {result['risk_level']}")
print(f"Confidence: {result['confidence']}")
print(f"Reasoning: {result['reasoning']}")
```

Run the test:

```bash
python test_gemini.py
```

## Model Selection

### gemini-1.5-pro (Default)

- **Best for**: Production use, complex reasoning, high accuracy
- **Speed**: Moderate
- **Cost**: Higher
- **Use when**: Accuracy is critical

### gemini-1.5-flash

- **Best for**: Development, testing, high-volume scenarios
- **Speed**: Fast
- **Cost**: Lower
- **Use when**: Speed and cost matter more than maximum accuracy

To switch models, update `.env`:

```env
GEMINI_MODEL=gemini-1.5-flash
```

## Security Best Practices

### ✅ DO

- Store API keys in `.env` file
- Add `.env` to `.gitignore`
- Use environment variables in code
- Rotate API keys regularly
- Use project-scoped keys from Google AI Studio

### ❌ DON'T

- Hardcode API keys in source code
- Commit `.env` to git
- Share API keys in screenshots or demos
- Log or print API keys
- Use personal API keys in production

## Troubleshooting

### "Missing GOOGLE_GEMINI_API_KEY"

**Problem**: API key not found in environment

**Solution**:
1. Verify `.env` file exists in project root
2. Check `.env` contains `GOOGLE_GEMINI_API_KEY=...`
3. Ensure no spaces around `=`
4. Restart your Python interpreter

### "google-generativeai not installed"

**Problem**: Gemini SDK not installed

**Solution**:
```bash
pip install google-generativeai
```

### "API key not valid"

**Problem**: Invalid or expired API key

**Solution**:
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Generate a new API key
3. Update `.env` with new key

### "Model not found"

**Problem**: Invalid model name

**Solution**:
Use only supported models:
- `gemini-1.5-pro`
- `gemini-1.5-flash`

## Architecture Parity with ERNIE

This Gemini integration mirrors the ERNIE architecture pattern:

| Component | ERNIE Project | Gemini Project |
|-----------|---------------|----------------|
| **Provider** | Baidu ERNIE | Google Gemini |
| **API Source** | Baidu Cloud | Google AI Studio |
| **Config** | Environment-based | Environment-based |
| **Security** | No hardcoded keys | No hardcoded keys |
| **Model** | ERNIE-Bot | gemini-1.5-pro |
| **Architecture** | Same level | Same level |

## Hackathon Compliance

✅ **This project uses Google's Gemini platform via Google AI Studio**

✅ **Leveraging Gemini 1.5 Pro for state-of-the-art multimodal reasoning**

✅ **Secure, production-grade architecture with environment-based configuration**

✅ **No API keys in source code, commits, or documentation**

✅ **Fully compliant with Gemini Hackathon rules**

## Next Steps

1. ✅ Get API key from Google AI Studio
2. ✅ Configure `.env` file
3. ✅ Install dependencies
4. ✅ Test integration
5. 📝 Review [prompts/README.md](prompts/README.md) for prompt engineering
6. 🚀 Deploy using [deployment/README.md](deployment/README.md)

## Support

- **Google AI Studio**: https://makersuite.google.com
- **Gemini API Docs**: https://ai.google.dev/docs
- **Project Issues**: Check CloudWatch logs for errors
