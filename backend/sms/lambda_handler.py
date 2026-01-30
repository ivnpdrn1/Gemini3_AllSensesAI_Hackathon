"""
AllSensesAI Gemini3 Guardian - SMS Sending Lambda
Sends real SMS alerts via AWS SNS with E.164 validation
Supports international SMS (E.164 format)
"""

import json
import boto3
import re
import logging
from datetime import datetime, timezone
from typing import Dict, Any

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize SNS client
sns = boto3.client('sns')

# E.164 phone number regex: +[country code][number] (7-15 digits total)
E164_PATTERN = re.compile(r'^\+[1-9]\d{6,14}$')

# SMS length limits (conservative for international)
MAX_SMS_LENGTH = 1600  # SNS limit
SAFE_SMS_LENGTH = 1400  # Recommended for international


def handler(event, context):
    """
    Lambda handler for SMS sending with international support
    
    Expected payload:
    {
        "buildId": "GEMINI3-JURY-READY-VIDEO-SMS-20260128-v2",
        "victimName": "John Doe",
        "to": "+1234567890",  # E.164 format
        "message": "🚨 EMERGENCY ALERT\n\nVictim: John Doe\n...",
        "meta": {
            "risk": "HIGH",
            "lat": 4.7110,
            "lng": -74.0721,
            "timestamp": "2026-01-28T12:34:56.789Z"
        }
    }
    """
    logger.info(f"[SMS-LAMBDA] Received event")
    
    try:
        # Handle CORS preflight
        if event.get('httpMethod') == 'OPTIONS':
            return cors_response(200, {'message': 'OK'})
        
        # Parse body
        if 'body' in event:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event
        
        # Validate required fields
        validation_error = validate_payload(body)
        if validation_error:
            logger.error(f"[SMS-LAMBDA] Validation error: {validation_error}")
            return cors_response(400, {
                'ok': False,
                'provider': 'sns',
                'errorCode': 'VALIDATION_ERROR',
                'errorMessage': validation_error,
                'toMasked': mask_phone(body.get('to', 'unknown')),
                'timestamp': datetime.now(timezone.utc).isoformat()
            })
        
        # Extract fields
        to_phone = body['to']
        sms_text = body['message']
        build_id = body.get('buildId', 'unknown')
        victim_name = body.get('victimName', 'Unknown')
        
        # Log attempt with masked phone
        to_masked = mask_phone(to_phone)
        logger.info(f"[SMS-LAMBDA] Publishing SMS to {to_masked}")
        logger.info(f"[SMS-LAMBDA] Message length: {len(sms_text)} chars")
        
        # Send SMS via SNS with proper attributes for international
        try:
            response = sns.publish(
                PhoneNumber=to_phone,
                Message=sms_text,
                MessageAttributes={
                    'AWS.SNS.SMS.SMSType': {
                        'DataType': 'String',
                        'StringValue': 'Transactional'
                    }
                }
            )
            
            message_id = response['MessageId']
            timestamp = datetime.now(timezone.utc).isoformat()
            
            logger.info(f"[SMS-LAMBDA] SMS published successfully. MessageId: {message_id}")
            
            return cors_response(200, {
                'ok': True,
                'provider': 'sns',
                'messageId': message_id,
                'toMasked': to_masked,
                'timestamp': timestamp,
                'buildId': build_id,
                'victimName': victim_name
            })
            
        except Exception as sns_error:
            logger.error(f"[SMS-LAMBDA] SNS publish failed: {str(sns_error)}", exc_info=True)
            return cors_response(500, {
                'ok': False,
                'provider': 'sns',
                'errorCode': 'SNS_PUBLISH_FAILED',
                'errorMessage': str(sns_error),
                'toMasked': to_masked,
                'timestamp': datetime.now(timezone.utc).isoformat()
            })
        
    except Exception as e:
        logger.error(f"[SMS-LAMBDA] Unexpected error: {str(e)}", exc_info=True)
        return cors_response(500, {
            'ok': False,
            'provider': 'sns',
            'errorCode': 'INTERNAL_ERROR',
            'errorMessage': f'Internal error: {str(e)}',
            'toMasked': 'unknown',
            'timestamp': datetime.now(timezone.utc).isoformat()
        })


def validate_payload(body: Dict[str, Any]) -> str:
    """
    Validate SMS payload
    
    Returns:
        Error message if validation fails, None if valid
    """
    # Check required fields (simplified contract)
    if 'to' not in body:
        return 'Missing required field: to'
    
    if 'message' not in body:
        return 'Missing required field: message'
    
    # Validate E.164 format
    to_phone = body['to']
    if not E164_PATTERN.match(to_phone):
        return f'Invalid phone number format. Must be E.164 format (e.g., +XXXXXXXXXXX international). Got: {to_phone}'
    
    # Validate SMS text length
    sms_text = body['message']
    if not sms_text or len(sms_text.strip()) == 0:
        return 'SMS text cannot be empty'
    
    if len(sms_text) > MAX_SMS_LENGTH:
        return f'SMS text too long ({len(sms_text)} chars). Maximum is {MAX_SMS_LENGTH} characters.'
    
    # Warn if over safe length (but don't fail)
    if len(sms_text) > SAFE_SMS_LENGTH:
        logger.warning(f"[SMS-LAMBDA] Message length {len(sms_text)} exceeds safe limit {SAFE_SMS_LENGTH} for international SMS")
    
    return None


def mask_phone(phone: str) -> str:
    """
    Mask phone number for privacy
    Example: +1234567890 -> +1***7890
    """
    if len(phone) < 8:
        return phone
    
    return phone[:3] + '***' + phone[-4:]


def cors_response(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
    """
    Create HTTP response with CORS headers
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': json.dumps(body)
    }
