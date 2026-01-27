"""
Gemini Emergency Demo Backend
Flask API for runtime proof and jury demonstrations

This backend provides:
1. Actual Gemini API integration
2. Runtime health checks
3. Fallback handling
4. Jury-safe logging
"""

import os
import json
import time
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import logging

# Load environment variables
load_dotenv()

# Import Gemini client
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from src.gemini.client import GeminiClient, GENAI_AVAILABLE

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for frontend

# Initialize Gemini client
gemini_client = None
gemini_available = False

try:
    gemini_client = GeminiClient()
    gemini_available = gemini_client.health_check()
    logger.info(f"Gemini client initialized: {gemini_available}")
except Exception as e:
    logger.error(f"Failed to initialize Gemini client: {str(e)}")
    gemini_available = False


@app.route('/health', methods=['GET'])
def health_check():
    """
    Runtime health check endpoint.
    Returns current system status for UI display.
    """
    return jsonify({
        'status': 'healthy',
        'gemini_available': gemini_available,
        'sdk_loaded': GENAI_AVAILABLE,
        'model_name': os.getenv('GEMINI_MODEL', 'gemini-1.5-pro'),
        'mode': 'LIVE' if gemini_available else 'FALLBACK',
        'timestamp': time.time()
    })


@app.route('/analyze', methods=['POST'])
def analyze_emergency():
    """
    Emergency analysis endpoint.
    Accepts transcript and context, returns Gemini risk assessment.
    """
    start_time = time.time()
    
    try:
        # Parse request
        data = request.get_json()
        transcript = data.get('transcript', '')
        location = data.get('location', '')
        name = data.get('name', 'Unknown')
        contact = data.get('contact', '')
        
        logger.info(f"Analysis request received: {len(transcript)} chars")
        
        # Build prompt
        prompt = build_emergency_prompt(transcript, location, name, contact)
        
        # Call Gemini
        if gemini_available and gemini_client:
            logger.info("Calling Gemini API...")
            result = gemini_client.analyze_emergency({}, prompt)
            result['mode'] = 'LIVE'
        else:
            logger.warning("Gemini unavailable, using fallback")
            result = fallback_analysis(transcript)
            result['mode'] = 'FALLBACK'
        
        # Add response time
        result['response_time'] = round(time.time() - start_time, 2)
        
        logger.info(f"Analysis complete: {result['risk_level']} (confidence: {result['confidence']})")
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Analysis error: {str(e)}")
        return jsonify({
            'risk_level': 'MEDIUM',
            'confidence': 0.0,
            'reasoning': f'Error during analysis: {str(e)}',
            'indicators': ['API_ERROR'],
            'recommended_action': 'MONITOR',
            'response_time': round(time.time() - start_time, 2),
            'mode': 'ERROR',
            'error': str(e)
        }), 500


def build_emergency_prompt(transcript: str, location: str, name: str, contact: str) -> str:
    """
    Build structured prompt for Gemini emergency analysis.
    """
    return f"""You are an AI emergency detection system analyzing a potential distress situation.

**Context**:
- Person: {name}
- Location: {location}
- Emergency Contact: {contact}

**Transcript**:
"{transcript}"

**Task**: Analyze this situation for emergency indicators and respond with a JSON object containing:

1. **risk_level**: One of ["CRITICAL", "HIGH", "MEDIUM", "LOW", "NONE"]
   - CRITICAL: Immediate life-threatening danger
   - HIGH: Serious threat requiring urgent response
   - MEDIUM: Concerning situation requiring monitoring
   - LOW: Minor concern, no immediate action needed
   - NONE: No emergency indicators detected

2. **confidence**: Float between 0.0 and 1.0 indicating certainty

3. **reasoning**: Detailed explanation of your assessment (2-3 sentences)

4. **indicators**: Array of specific distress signals detected (e.g., ["explicit_help_request", "fear_expressed", "stalking_concern"])

5. **recommended_action**: One of ["ALERT", "MONITOR", "NONE"]
   - ALERT: Trigger emergency response (911 + contacts)
   - MONITOR: Continue monitoring, prepare for escalation
   - NONE: No action needed

**Important**: 
- Be sensitive to subtle distress signals
- Consider context (location, time, explicit requests)
- Err on the side of caution for safety
- Respond ONLY with valid JSON, no additional text

Example response:
```json
{{
  "risk_level": "HIGH",
  "confidence": 0.85,
  "reasoning": "Explicit help request combined with fear expression and stalking concern indicates genuine distress. Location context supports urgency.",
  "indicators": ["explicit_help_request", "fear_expressed", "stalking_concern"],
  "recommended_action": "ALERT"
}}
```

Now analyze the situation above:"""


def fallback_analysis(transcript: str) -> dict:
    """
    Fallback analysis when Gemini is unavailable.
    Uses simple keyword matching for demo purposes.
    """
    logger.info("Using fallback analysis (keyword matching)")
    
    lower_transcript = transcript.lower()
    
    # Keyword detection
    keywords = {
        'help': ['help', 'help me', 'need help'],
        'fear': ['scared', 'afraid', 'frightened', 'terrified'],
        'danger': ['danger', 'dangerous', 'threat', 'threatening'],
        'unsafe': ['unsafe', "don't feel safe", 'not safe'],
        'following': ['following', 'stalking', 'chasing'],
        'attack': ['attack', 'attacking', 'hurt', 'hurting']
    }
    
    indicators = []
    confidence = 0.3  # Base confidence
    
    for category, words in keywords.items():
        if any(word in lower_transcript for word in words):
            indicators.append(f'{category}_detected')
            confidence += 0.15
    
    confidence = min(confidence, 1.0)
    
    # Determine risk level
    if confidence >= 0.8:
        risk_level = 'HIGH'
        action = 'ALERT'
    elif confidence >= 0.6:
        risk_level = 'MEDIUM'
        action = 'MONITOR'
    elif confidence >= 0.4:
        risk_level = 'LOW'
        action = 'MONITOR'
    else:
        risk_level = 'NONE'
        action = 'NONE'
    
    return {
        'risk_level': risk_level,
        'confidence': round(confidence, 2),
        'reasoning': f'Fallback analysis detected {len(indicators)} distress indicators using keyword matching. Gemini API unavailable.',
        'indicators': indicators if indicators else ['no_indicators'],
        'recommended_action': action
    }


if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    logger.info(f"Starting Gemini demo backend on port {port}")
    logger.info(f"Gemini available: {gemini_available}")
    logger.info(f"SDK loaded: {GENAI_AVAILABLE}")
    
    app.run(
        host='0.0.0.0',
        port=port,
        debug=os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    )
