"""
Production SMS Lambda Handler V4 - Colombia SMS Fix
Fixes three critical issues:
1. Backend returns HTTP 200 only when SNS publish succeeds with MessageId
2. Strict API contract with ok:true/false and proper error codes
3. Always includes requestId from AWS context

Supports Colombia +57 and all international numbers via AWS SNS
"""

import json
import boto3
import os
import re
from datetime import datetime

# Initialize SNS client
sns = boto3.client('sns', region_name='us-east-1')

def lambda_handler(event, context):
    """
    Lambda Function URL handler for emergency SMS delivery
    V4: Strict success/failure contract with MessageId requirement
    """
    
    print('[SMS-LAMBDA-V4] Received request')
    print('[SMS-LAMBDA-V4] Event:', json.dumps(event))
    
    # Get AWS request ID for tracking
    request_id = context.request_id if context else 'unknown'
    
    try:
        # Parse request body
        if 'body' in event:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event
        
        print('[SMS-LAMBDA-V4] Parsed body:', json.dumps(body))
        
        # Extract fields from new API contract
        phone_number = body.get('to')  # New field name
        message = body.get('message')  # New field name
        build_id = body.get('buildId', 'unknown')
        meta = body.get('meta', {})
        
        # Fallback to old field names for backward compatibility
        if not phone_number:
            phone_number = body.get('phoneNumber')
        if not message:
            message = body.get('emergencyMessage')
        
        # Extract metadata
        victim_name = meta.get('victimName', meta.get('victim', 'Unknown'))
        risk_level = meta.get('risk', 'UNKNOWN')
        lat = meta.get('lat', 0)
        lng = meta.get('lng', 0)
        
        # Validate required fields
        if not phone_number:
            return error_response(400, 'MISSING_PHONE', 'Missing required field: to (phone number)', phone_number, request_id)
        
        if not message:
            return error_response(400, 'MISSING_MESSAGE', 'Missing required field: message', phone_number, request_id)
        
        # Validate E.164 format (+ followed by 8-15 digits)
        e164_pattern = r'^\+[1-9]\d{7,14}$'
        if not re.match(e164_pattern, phone_number):
            return error_response(
                400, 
                'INVALID_PHONE_FORMAT', 
                f'Phone number must be in E.164 format: +[country code][number]. Example: +573222063010 or +12025551234. Received: {phone_number}',
                phone_number,
                request_id
            )
        
        print(f'[SMS-LAMBDA-V4] Sending SMS to {phone_number}')
        print(f'[SMS-LAMBDA-V4] Victim: {victim_name}')
        print(f'[SMS-LAMBDA-V4] Risk: {risk_level}')
        print(f'[SMS-LAMBDA-V4] Build ID: {build_id}')
        print(f'[SMS-LAMBDA-V4] Message length: {len(message)} chars')
        print(f'[SMS-LAMBDA-V4] Location: {lat}, {lng}')
        
        # Send SMS via SNS with international reliability settings
        try:
            sns_response = sns.publish(
                PhoneNumber=phone_number,
                Message=message,
                MessageAttributes={
                    'AWS.SNS.SMS.SMSType': {
                        'DataType': 'String',
                        'StringValue': 'Transactional'  # High-priority delivery
                    },
                    'AWS.SNS.SMS.MaxPrice': {
                        'DataType': 'String',
                        'StringValue': '0.50'  # Reasonable max price for international
                    }
                }
            )
            
            print(f'[SMS-LAMBDA-V4] SNS Response:', json.dumps(sns_response, default=str))
            
        except Exception as sns_error:
            print(f'[SMS-LAMBDA-V4] SNS Publish Exception: {str(sns_error)}')
            return error_response(
                502,
                'SNS_PUBLISH_FAILED',
                f'SNS publish failed: {str(sns_error)}',
                phone_number,
                request_id
            )
        
        # CRITICAL: Validate MessageId exists
        message_id = sns_response.get('MessageId')
        
        if not message_id:
            print(f'[SMS-LAMBDA-V4] ERROR: SNS returned success but no MessageId!')
            print(f'[SMS-LAMBDA-V4] SNS Response: {json.dumps(sns_response, default=str)}')
            return error_response(
                502,
                'NO_MESSAGE_ID',
                'SNS publish returned success but no MessageId was provided',
                phone_number,
                request_id
            )
        
        print(f'[SMS-LAMBDA-V4] ✅ SMS sent successfully')
        print(f'[SMS-LAMBDA-V4] MessageId: {message_id}')
        
        # Return success response (HTTP 200 with ok:true and messageId)
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({
                'ok': True,
                'provider': 'sns',
                'messageId': message_id,
                'toMasked': mask_phone(phone_number),
                'requestId': request_id,
                'timestamp': datetime.utcnow().isoformat() + 'Z'
            })
        }
        
    except json.JSONDecodeError as e:
        print(f'[SMS-LAMBDA-V4] JSON Parse Error: {str(e)}')
        return error_response(400, 'INVALID_JSON', f'Invalid JSON in request body: {str(e)}', None, request_id)
        
    except Exception as e:
        print(f'[SMS-LAMBDA-V4] Unexpected Error: {str(e)}')
        import traceback
        traceback.print_exc()
        return error_response(500, 'INTERNAL_ERROR', f'Internal server error: {str(e)}', None, request_id)


def error_response(status_code, error_code, error_message, phone_number, request_id):
    """
    Return error response with CORS headers
    CRITICAL: Never return HTTP 200 for errors
    """
    return {
        'statusCode': status_code,  # Must be non-200 for errors
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': json.dumps({
            'ok': False,  # Always false for errors
            'provider': 'sns',
            'errorCode': error_code,
            'errorMessage': error_message,
            'toMasked': mask_phone(phone_number) if phone_number else 'N/A',
            'requestId': request_id,
            'timestamp': datetime.utcnow().isoformat() + 'Z'
        })
    }


def mask_phone(phone):
    """Mask phone number for privacy (e.g., +1234567890 -> +1***7890)"""
    if not phone:
        return 'N/A'
    if len(phone) > 6:
        return phone[:3] + '***' + phone[-4:]
    return phone
