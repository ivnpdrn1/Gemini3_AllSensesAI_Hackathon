# Gemini 3 Integration Layer

## Overview

This module provides the interface between AllSensesAI and Google Gemini 3 API. All intelligence operations flow through this layer.

## Files

### client.py
**Purpose**: Gemini 3 API client wrapper

**Key Functions**:
- `initialize_client()` - Set up Gemini 3 API connection
- `analyze_emergency()` - Send multimodal input for analysis
- `parse_response()` - Parse and validate Gemini 3 JSON response
- `handle_errors()` - Retry logic and error handling

**TODO**: Implement Vertex AI or AI Studio SDK integration

### multimodal.py
**Purpose**: Prepare multimodal inputs for Gemini 3

**Key Functions**:
- `prepare_text_input()` - Format text transcripts
- `prepare_audio_features()` - Extract audio characteristics
- `prepare_image_input()` - Encode images for API
- `combine_modalities()` - Merge inputs into single request

**TODO**: Implement audio feature extraction and image encoding

### prompts.py
**Purpose**: Manage prompt templates and versioning

**Key Functions**:
- `load_prompt()` - Load prompt template by name
- `format_prompt()` - Insert context into template
- `validate_prompt()` - Check prompt structure
- `version_prompt()` - Track prompt versions

**TODO**: Implement prompt template loading from markdown files

## Usage Example

```python
from src.gemini import client, multimodal

# Initialize Gemini 3 client
gemini_client = client.initialize_client(api_key=API_KEY)

# Prepare multimodal input
input_data = multimodal.combine_modalities(
    text="Help! Someone is following me",
    audio_features={"tone": "fearful", "volume": "whispered"},
    location={"lat": 37.7749, "lng": -122.4194}
)

# Analyze with Gemini 3
response = gemini_client.analyze_emergency(input_data)

# Parse structured output
risk_assessment = client.parse_response(response)
print(f"Risk Level: {risk_assessment['risk_level']}")
print(f"Confidence: {risk_assessment['confidence']}")
print(f"Reasoning: {risk_assessment['reasoning']}")
```

## API Configuration

### Vertex AI (Recommended for Production)
```python
import vertexai
from vertexai.generative_models import GenerativeModel

vertexai.init(project="your-project-id", location="us-central1")
model = GenerativeModel("gemini-3-pro")
```

### AI Studio (Development/Testing)
```python
import google.generativeai as genai

genai.configure(api_key="YOUR_API_KEY")
model = genai.GenerativeModel("gemini-3-pro")
```

## Error Handling

The client implements robust error handling:

1. **Rate Limiting**: Exponential backoff with jitter
2. **Timeout**: 30-second timeout with retry
3. **Invalid Response**: Schema validation and fallback
4. **API Errors**: Graceful degradation

## Monitoring

Track these metrics:
- API latency (p50, p95, p99)
- Error rate by type
- Token usage per request
- Cache hit rate

## Security

- API keys stored in AWS Secrets Manager
- All requests use HTTPS
- Input sanitization before API calls
- Response validation before use

## Compliance

All code in this module is **original work** created for the Google Gemini 3 Hackathon. No code from previous systems has been copied or adapted.
