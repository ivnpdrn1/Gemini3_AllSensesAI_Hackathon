"""
Gemini Lambda Handler
AWS Lambda function for Gemini emergency analysis

This handler provides:
1. Health check endpoint
2. Emergency analysis endpoint
3. Gemini API integration
4. Fallback handling
5. CORS support
"""

import json
import os
import time
import logging
import boto3
from typing import Dict, Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize SSM client for parameter store
ssm = boto3.client('ssm')

# Global variables for caching
GEMINI_CLIENT = None
GEMINI_AVAILABLE = False
API_KEY_CACHED = None


def get_api_key() -> str:
    """
    Retrieve Gemini API key from SSM Parameter Store.
    Caches the key for subsequent invocations.
    """
    global API_KEY_CACHED
    
    if API_KEY_CACHED:
        return API_KEY_CACHED
    
    try:
        parameter_name = os.environ.get('GEMINI_API_KEY_PARAMETER', '/allsensesai/gemini/api-key')
        response = ssm.get_parameter(Name=parameter_name, WithDecryption=True)
        API_KEY_CACHED = response['Parameter']['Value']
        logger.info("Retrieved API key from Parameter Store")
        return API_KEY_CACHED
    except Exception as e:
        logger.error(f"Failed to retrieve API key: {str(e)}")
        raise


def initialize_gemini():
    """
    Initialize Gemini client.
    Called once per Lambda container lifecycle.
    """
    global GEMINI_CLIENT, GEMINI_AVAILABLE
    
    if GEMINI_CLIENT is not None:
        return
    
    try:
        # Import Gemini SDK
        import google.generativeai as genai
        
        # Get API key
        api_key = get_api_key()
        
        # Configure Gemini
        genai.configure(api_key=api_key)
        
        # Get model name from environment
        model_name = os.environ.get('GEMINI_MODEL', 'gemini-1.5-pro')
        
        # Initialize model
        GEMINI_CLIENT = genai.GenerativeModel(model_name)
        GEMINI_AVAILABLE = True
        
        logger.info(f"Gemini client initialized: {model_name}")
        
    except ImportError:
        logger.error("google-generativeai SDK not available")
        GEMINI_AVAILABLE = False
    except Exception as e:
        logger.error(f"Failed to initialize Gemini: {str(e)}")
        GEMINI_AVAILABLE = False


def lambda_handler(event, context):
    """
    Main Lambda handler.
    Routes requests to appropriate endpoints.
    """
    # Initialize Gemini on cold start
    initialize_gemini()
    
    # Parse request
    try:
        # Handle both API Gateway and Function URL formats
        if 'requestContext' in event and 'http' in event['requestContext']:
            # Function URL format
            method = event['requestContext']['http']['method']
            path = event['requestContext']['http']['path']
        else:
            # API Gateway format
            method = event.get('httpMethod', 'GET')
            path = event.get('path', '/')
        
        logger.info(f"Request: {method} {path}")
        
        # Route request
        if method == 'GET' and path == '/health':
            return handle_health_check()
        elif method == 'POST' and path == '/analyze':
            return handle_analyze(event)
        elif method == 'OPTIONS':
            return cors_response(200, {})
        else:
            return cors_response(404, {'error': 'Not found'})
            
    except Exception as e:
        logger.error(f"Handler error: {str(e)}")
        return cors_response(500, {'error': str(e)})


def handle_health_check() -> Dict[str, Any]:
    """
    Health check endpoint.
    Returns current system status.
    """
    return cors_response(200, {
        'status': 'healthy',
        'gemini_available': GEMINI_AVAILABLE,
        'sdk_loaded': GEMINI_CLIENT is not None,
        'model_name': os.environ.get('GEMINI_MODEL', 'gemini-1.5-pro'),
        'mode': 'LIVE' if GEMINI_AVAILABLE else 'FALLBACK',
        'timestamp': time.time()
    })


def handle_analyze(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Emergency analysis endpoint.
    Accepts transcript and context, returns Gemini risk assessment.
    """
    start_time = time.time()
    
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        transcript = body.get('transcript', '')
        location = body.get('location', '')
        name = body.get('name', 'Unknown')
        contact = body.get('contact', '')
        
        logger.info(f"Analysis request: {len(transcript)} chars")
        
        # Build prompt
        prompt = build_emergency_prompt(transcript, location, name, contact)
        
        # Call Gemini
        if GEMINI_AVAILABLE and GEMINI_CLIENT:
            logger.info("Calling Gemini API...")
            result = call_gemini(prompt)
            result['mode'] = 'LIVE'
        else:
            logger.warning("Gemini unavailable, using fallback")
            result = fallback_analysis(transcript)
            result['mode'] = 'FALLBACK'
        
        # Add response time
        result['response_time'] = round(time.time() - start_time, 2)
        
        logger.info(f"Analysis complete: {result['risk_level']} (confidence: {result['confidence']})")
        
        return cors_response(200, result)
        
    except Exception as e:
        logger.error(f"Analysis error: {str(e)}")
        return cors_response(500, {
            'risk_level': 'MEDIUM',
            'confidence': 0.0,
            'reasoning': f'Error during analysis: {str(e)}',
            'indicators': ['API_ERROR'],
            'recommended_action': 'MONITOR',
            'response_time': round(time.time() - start_time, 2),
            'mode': 'ERROR',
            'error': str(e)
        })


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


def call_gemini(prompt: str) -> Dict[str, Any]:
    """
    Call Gemini API for emergency analysis.
    """
    try:
        response = GEMINI_CLIENT.generate_content(
            prompt,
            generation_config={
                "temperature": 0.7,
                "top_p": 0.95,
                "top_k": 40,
                "max_output_tokens": 2048,
            }
        )
        
        # Extract text response
        response_text = response.text
        
        # Parse JSON response
        return parse_gemini_response(response_text)
        
    except Exception as e:
        logger.error(f"Gemini API error: {str(e)}")
        return {
            'risk_level': 'MEDIUM',
            'confidence': 0.0,
            'reasoning': f'Gemini API error: {str(e)}',
            'indicators': ['API_ERROR'],
            'recommended_action': 'MONITOR'
        }


def parse_gemini_response(response_text: str) -> Dict[str, Any]:
    """
    Parse and validate Gemini JSON response.
    """
    try:
        # Extract JSON from response (may be wrapped in markdown)
        if "```json" in response_text:
            start = response_text.find("```json") + 7
            end = response_text.find("```", start)
            response_text = response_text[start:end].strip()
        elif "```" in response_text:
            start = response_text.find("```") + 3
            end = response_text.find("```", start)
            response_text = response_text[start:end].strip()
        
        response = json.loads(response_text)
        
        # Validate required fields
        required_fields = ['risk_level', 'confidence', 'reasoning', 'indicators', 'recommended_action']
        for field in required_fields:
            if field not in response:
                raise ValueError(f"Missing required field: {field}")
        
        return response
        
    except Exception as e:
        logger.error(f"Failed to parse Gemini response: {str(e)}")
        return {
            'risk_level': 'MEDIUM',
            'confidence': 0.0,
            'reasoning': f'Failed to parse Gemini response: {str(e)}',
            'indicators': ['PARSE_ERROR'],
            'recommended_action': 'MONITOR'
        }


def fallback_analysis(transcript: str) -> Dict[str, Any]:
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
    confidence = 0.3
    
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


def cors_response(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
    """
    Build CORS-enabled response.
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': json.dumps(body)
    }
