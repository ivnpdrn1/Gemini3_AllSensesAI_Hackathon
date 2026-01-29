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
    Matches working reference pattern for proven international delivery
    """
    
    print('[SMS-LAMBDA] Received request')
    print('[SMS-LAMBDA] Event:', json.dumps(event))
    
    try:
        # Parse request body
        if 'body' in event:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event
        
        print('[SMS-LAMBDA] Parsed body:', json.dumps(body))
        
        # Extract required fields (matching working reference)
        action = body.get('action', 'EMERGENCY_ALERT')
        victim_name = body.get('victimName', 'Unknown')
        phone_number = body.get('phoneNumber')
        emergency_message = body.get('emergencyMessage')
        detection_type = body.get('detectionType', 'MANUAL')
        timestamp = body.get('timestamp', datetime.utcnow().isoformat())
        location = body.get('location', {})
        
        # Validate required fields
        if not phone_number:
            return error_response(400, 'Missing required field: phoneNumber')
        
        if not emergency_message:
            return error_response(400, 'Missing required field: emergencyMessage')
        
        # Validate E.164 format
        if not phone_number.startswith('+'):
            return error_response(400, f'Invalid phone format: {phone_number}. Must use E.164 format (e.g., +1234567890 or +573222063010)')
        
        print(f'[SMS-LAMBDA] Sending SMS to {phone_number}')
        print(f'[SMS-LAMBDA] Victim: {victim_name}')
        print(f'[SMS-LAMBDA] Detection: {detection_type}')
        print(f'[SMS-LAMBDA] Message length: {len(emergency_message)} chars')
        
        # Send SMS via SNS (matching working reference pattern)
        # Uses account-level defaults for international SMS
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
        
        # Return response (matching working reference format)
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',  # CORS for CloudFront
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({
                'smsMessageId': message_id,
                'status': 'SENT',
                'timestamp': datetime.utcnow().isoformat(),
                'phoneNumber': mask_phone(phone_number),
                'victimName': victim_name,
                'detectionType': detection_type
            })
        }
        
    except Exception as e:
        print(f'[SMS-LAMBDA] ERROR: {str(e)}')
        import traceback
        traceback.print_exc()
        return error_response(500, f'Internal server error: {str(e)}')


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
