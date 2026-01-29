"""
Production SMS Lambda Handler - Function URL Pattern
Matches working reference architecture for international SMS delivery
Supports Colombia +57 and all international numbers via AWS SNS
"""

import json
import boto3
import os
from datetime import datetime

# Initialize SNS client
sns = boto3.client('sns', region_name='us-east-1')

def lambda_handler(event, context):
    """
    Lambda Function URL handler for emergency SMS delivery
    Supports BOTH payload formats for backward compatibility:
    
    Format A (new): {to, message, buildId, victimName, meta}
    Format B (legacy): {phoneNumber, emergencyMessage, victimName, detectionType}
    """
    
    print('[SMS-LAMBDA] Received request')
    print('[SMS-LAMBDA] Event:', json.dumps(event, default=str))
    
    try:
        # Handle OPTIONS preflight explicitly
        if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
            print('[SMS-LAMBDA] OPTIONS preflight request')
            return cors_response(200, {'message': 'OK'})
        
        # Parse request body
        if 'body' in event:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event
        
        print('[SMS-LAMBDA] Parsed body:', json.dumps(body, default=str))
        
        # NORMALIZE PAYLOAD - Accept both formats
        # Format A: {to, message, buildId, victimName, meta}
        # Format B: {phoneNumber, emergencyMessage, victimName, detectionType}
        
        phone_number = body.get('to') or body.get('phoneNumber')
        emergency_message = body.get('message') or body.get('emergencyMessage')
        victim_name = body.get('victimName', 'Unknown')
        detection_type = body.get('detectionType', 'MANUAL')
        build_id = body.get('buildId', 'unknown')
        timestamp = body.get('timestamp', datetime.utcnow().isoformat())
        location = body.get('location') or body.get('meta', {})
        
        print(f'[SMS-LAMBDA] Normalized fields:')
        print(f'[SMS-LAMBDA]   phone_number: {mask_phone(phone_number) if phone_number else "MISSING"}')
        print(f'[SMS-LAMBDA]   message_length: {len(emergency_message) if emergency_message else 0}')
        print(f'[SMS-LAMBDA]   victim_name: {victim_name}')
        print(f'[SMS-LAMBDA]   detection_type: {detection_type}')
        print(f'[SMS-LAMBDA]   build_id: {build_id}')
        
        # Validate required fields
        if not phone_number:
            error_msg = 'Missing required field: phoneNumber or to'
            print(f'[SMS-LAMBDA] VALIDATION ERROR: {error_msg}')
            return cors_response(400, {
                'ok': False,
                'provider': 'sns',
                'errorCode': 'VALIDATION_ERROR',
                'errorMessage': error_msg,
                'timestamp': datetime.utcnow().isoformat()
            })
        
        if not emergency_message:
            error_msg = 'Missing required field: emergencyMessage or message'
            print(f'[SMS-LAMBDA] VALIDATION ERROR: {error_msg}')
            return cors_response(400, {
                'ok': False,
                'provider': 'sns',
                'errorCode': 'VALIDATION_ERROR',
                'errorMessage': error_msg,
                'timestamp': datetime.utcnow().isoformat()
            })
        
        # Validate E.164 format
        if not phone_number.startswith('+'):
            error_msg = f'Invalid phone format: {phone_number}. Must use E.164 format (e.g., +1234567890 or +573222063010)'
            print(f'[SMS-LAMBDA] VALIDATION ERROR: {error_msg}')
            return cors_response(400, {
                'ok': False,
                'provider': 'sns',
                'errorCode': 'INVALID_PHONE_FORMAT',
                'errorMessage': error_msg,
                'toMasked': mask_phone(phone_number),
                'timestamp': datetime.utcnow().isoformat()
            })
        
        print(f'[SMS-LAMBDA] Sending SMS to {mask_phone(phone_number)}')
        print(f'[SMS-LAMBDA] Victim: {victim_name}')
        print(f'[SMS-LAMBDA] Detection: {detection_type}')
        print(f'[SMS-LAMBDA] Message length: {len(emergency_message)} chars')
        
        # Send SMS via SNS
        try:
            sns_response = sns.publish(
                PhoneNumber=phone_number,
                Message=emergency_message,
                MessageAttributes={
                    'AWS.SNS.SMS.SMSType': {
                        'DataType': 'String',
                        'StringValue': 'Transactional'  # High-priority delivery
                    }
                }
            )
            
            message_id = sns_response['MessageId']
            
            print(f'[SMS-LAMBDA] SMS sent successfully')
            print(f'[SMS-LAMBDA] MessageId: {message_id}')
            
            # Return response (supports both frontend formats)
            return cors_response(200, {
                'ok': True,
                'provider': 'sns',
                'messageId': message_id,
                'smsMessageId': message_id,  # Legacy compatibility
                'status': 'SENT',
                'timestamp': datetime.utcnow().isoformat(),
                'toMasked': mask_phone(phone_number),
                'phoneNumber': mask_phone(phone_number),  # Legacy compatibility
                'victimName': victim_name,
                'detectionType': detection_type,
                'buildId': build_id
            })
            
        except Exception as sns_error:
            error_msg = f'SNS publish failed: {str(sns_error)}'
            print(f'[SMS-LAMBDA] ERROR: {error_msg}')
            import traceback
            traceback.print_exc()
            return cors_response(500, {
                'ok': False,
                'provider': 'sns',
                'errorCode': 'SNS_PUBLISH_FAILED',
                'errorMessage': error_msg,
                'toMasked': mask_phone(phone_number),
                'timestamp': datetime.utcnow().isoformat()
            })
        
    except Exception as e:
        error_msg = f'Internal server error: {str(e)}'
        print(f'[SMS-LAMBDA] UNEXPECTED ERROR: {error_msg}')
        import traceback
        traceback.print_exc()
        return cors_response(500, {
            'ok': False,
            'provider': 'sns',
            'errorCode': 'INTERNAL_ERROR',
            'errorMessage': error_msg,
            'timestamp': datetime.utcnow().isoformat()
        })


def cors_response(status_code, body_dict):
    """
    Create HTTP response with CORS headers
    CRITICAL: CORS headers MUST be on ALL responses (success + error)
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': json.dumps(body_dict, default=str)
    }


def error_response(status_code, message):
    """
    DEPRECATED: Use cors_response() instead
    Kept for backward compatibility
    """
    return cors_response(status_code, {
        'error': message,
        'timestamp': datetime.utcnow().isoformat()
    })

def error_response(status_code, message):
    """Return error response with CORS headers"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': json.dumps({
            'error': message,
            'timestamp': datetime.utcnow().isoformat()
        })
    }


def mask_phone(phone):
    """Mask phone number for privacy (e.g., +1234567890 -> +1***7890)"""
    if len(phone) > 6:
        return phone[:3] + '***' + phone[-4:]
    return phone
