"""
Production SMS Lambda Handler V5 - Enhanced Error Translation
Builds on V4 with comprehensive error handling:
1. Polls CloudWatch logs for actual delivery status
2. Translates carrier error codes to user-friendly messages
3. Provides remediation steps for each error type
4. Never returns UNKNOWN_ERROR without attempting to get details

Integrates DeliveryStatusPoller and ErrorCodeTranslator modules
"""

import json
import boto3
import os
import re
from datetime import datetime
from delivery_status_poller import DeliveryStatusPoller
from error_code_translator import ErrorCodeTranslator

# Initialize AWS clients
sns = boto3.client('sns', region_name='us-east-1')

# Initialize error handling modules
delivery_poller = DeliveryStatusPoller()
error_translator = ErrorCodeTranslator()

def lambda_handler(event, context):
    """
    Lambda Function URL handler for emergency SMS delivery
    V5: Enhanced error handling with CloudWatch log polling and error translation
    
    Flow:
    1. Validate request
    2. Publish to SNS
    3. If MessageId returned, poll CloudWatch for delivery status
    4. Translate error codes if delivery failed
    5. Return structured response with specific error details
    """
    
    print('[SMS-LAMBDA-V5] Received request')
    print('[SMS-LAMBDA-V5] Event:', json.dumps(event))
    
    # Get AWS request ID for tracking
    request_id = context.aws_request_id if context else 'unknown'
    
    # Log request details for CORS debugging
    method = event.get('requestContext', {}).get('http', {}).get('method', 'UNKNOWN')
    origin = event.get('headers', {}).get('origin', 'NO_ORIGIN')
    print(f'[SMS-LAMBDA-V5] Method: {method}, Origin: {origin}, RequestId: {request_id}')
    
    # Handle CORS preflight (OPTIONS request)
    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        print('[SMS-LAMBDA-V5] Handling OPTIONS preflight request')
        origin = event.get('headers', {}).get('origin', 'https://dfc8ght8abwqc.cloudfront.net')
        print(f'[SMS-LAMBDA-V5] Origin header: {origin}')
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': 'https://dfc8ght8abwqc.cloudfront.net',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'content-type',
                'Access-Control-Max-Age': '86400'
            },
            'body': ''
        }
    
    try:
        # Parse request body
        if 'body' in event:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event
        
        print('[SMS-LAMBDA-V5] Parsed body:', json.dumps(body))
        
        # Extract fields from API contract
        phone_number = body.get('to')
        message = body.get('message')
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
            return error_response(
                400, 
                'MISSING_PHONE', 
                'Missing required field: to (phone number)', 
                None,
                phone_number, 
                request_id
            )
        
        if not message:
            return error_response(
                400, 
                'MISSING_MESSAGE', 
                'Missing required field: message',
                None, 
                phone_number, 
                request_id
            )
        
        # Validate E.164 format (+ followed by 8-15 digits)
        e164_pattern = r'^\+[1-9]\d{7,14}$'
        if not re.match(e164_pattern, phone_number):
            return error_response(
                400, 
                'INVALID_PHONE_FORMAT', 
                f'Phone number must be in E.164 format: +[country code][number]. Example: +1234567890 or +12025551234. Received: {phone_number}',
                'Use E.164 format: +[country code][number]',
                phone_number,
                request_id
            )
        
        print(f'[SMS-LAMBDA-V5] Sending SMS to {phone_number}')
        print(f'[SMS-LAMBDA-V5] Victim: {victim_name}')
        print(f'[SMS-LAMBDA-V5] Risk: {risk_level}')
        print(f'[SMS-LAMBDA-V5] Build ID: {build_id}')
        print(f'[SMS-LAMBDA-V5] Message length: {len(message)} chars')
        print(f'[SMS-LAMBDA-V5] Location: {lat}, {lng}')
        
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
                    },
                    'AWS.SNS.SMS.SenderID': {
                        'DataType': 'String',
                        'StringValue': 'AllSenses'  # Sender identification
                    }
                }
            )
            
            print(f'[SMS-LAMBDA-V5] SNS Response:', json.dumps(sns_response, default=str))
            
        except Exception as sns_error:
            print(f'[SMS-LAMBDA-V5] SNS Publish Exception: {str(sns_error)}')
            
            # Try to translate SNS error
            error_translation = error_translator.translate_error(str(sns_error), 'FAILED')
            
            return error_response(
                502,
                error_translation.error_code,
                error_translation.user_message,
                error_translation.remediation,
                phone_number,
                request_id
            )
        
        # CRITICAL: Validate MessageId exists
        message_id = sns_response.get('MessageId')
        
        if not message_id:
            print(f'[SMS-LAMBDA-V5] ERROR: SNS returned success but no MessageId!')
            print(f'[SMS-LAMBDA-V5] SNS Response: {json.dumps(sns_response, default=str)}')
            return error_response(
                502,
                'NO_MESSAGE_ID',
                'SNS publish returned success but no MessageId was provided',
                'Check SNS configuration and IAM permissions',
                phone_number,
                request_id
            )
        
        print(f'[SMS-LAMBDA-V5] MessageId received: {message_id}')
        
        # NEW: Poll CloudWatch logs for delivery status
        print(f'[SMS-LAMBDA-V5] Polling CloudWatch logs for delivery status...')
        try:
            delivery_status = delivery_poller.poll_delivery_status(
                message_id=message_id,
                max_attempts=3,
                initial_backoff_seconds=2
            )
            
            print(f'[SMS-LAMBDA-V5] Delivery status: {delivery_status.status}')
            
            if delivery_status.status == 'FAILED':
                # NEW: Translate error code
                print(f'[SMS-LAMBDA-V5] Delivery failed. Provider response: {delivery_status.provider_response}')
                
                error_translation = error_translator.translate_error(
                    delivery_status.provider_response,
                    delivery_status.status
                )
                
                print(f'[SMS-LAMBDA-V5] Translated error code: {error_translation.error_code}')
                print(f'[SMS-LAMBDA-V5] User message: {error_translation.user_message}')
                
                return error_response(
                    502,
                    error_translation.error_code,
                    error_translation.user_message,
                    error_translation.remediation,
                    phone_number,
                    request_id,
                    message_id=message_id
                )
            
            elif delivery_status.status == 'PENDING':
                # Logs not available yet - return success with note
                print(f'[SMS-LAMBDA-V5] Delivery status pending (logs not available yet)')
                print(f'[SMS-LAMBDA-V5] ✅ SMS sent successfully (delivery status pending)')
                
                return {
                    'statusCode': 200,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': 'https://dfc8ght8abwqc.cloudfront.net',
                        'Access-Control-Allow-Methods': 'POST, OPTIONS',
                        'Access-Control-Allow-Headers': 'content-type'
                    },
                    'body': json.dumps({
                        'ok': True,
                        'provider': 'sns',
                        'messageId': message_id,
                        'deliveryStatus': 'PENDING',
                        'note': 'Message accepted by SNS. Delivery status will be available in CloudWatch logs within 2-5 minutes.',
                        'toMasked': mask_phone(phone_number),
                        'requestId': request_id,
                        'timestamp': datetime.utcnow().isoformat() + 'Z'
                    })
                }
            
            else:  # SUCCESS
                print(f'[SMS-LAMBDA-V5] ✅ SMS delivered successfully')
                print(f'[SMS-LAMBDA-V5] Carrier: {delivery_status.phone_carrier}')
                print(f'[SMS-LAMBDA-V5] Price: ${delivery_status.price_usd}')
                
                return {
                    'statusCode': 200,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': 'https://dfc8ght8abwqc.cloudfront.net',
                        'Access-Control-Allow-Methods': 'POST, OPTIONS',
                        'Access-Control-Allow-Headers': 'content-type'
                    },
                    'body': json.dumps({
                        'ok': True,
                        'provider': 'sns',
                        'messageId': message_id,
                        'deliveryStatus': 'SUCCESS',
                        'carrier': delivery_status.phone_carrier,
                        'priceUSD': delivery_status.price_usd,
                        'toMasked': mask_phone(phone_number),
                        'requestId': request_id,
                        'timestamp': datetime.utcnow().isoformat() + 'Z'
                    })
                }
                
        except Exception as poll_error:
            # Polling failed - return success with warning
            print(f'[SMS-LAMBDA-V5] CloudWatch polling error: {str(poll_error)}')
            print(f'[SMS-LAMBDA-V5] ✅ SMS sent successfully (delivery status unavailable)')
            
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': 'https://dfc8ght8abwqc.cloudfront.net',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'content-type'
                },
                'body': json.dumps({
                    'ok': True,
                    'provider': 'sns',
                    'messageId': message_id,
                    'deliveryStatus': 'UNKNOWN',
                    'note': 'Message accepted by SNS. Delivery status could not be retrieved from CloudWatch logs.',
                    'toMasked': mask_phone(phone_number),
                    'requestId': request_id,
                    'timestamp': datetime.utcnow().isoformat() + 'Z'
                })
            }
        
    except json.JSONDecodeError as e:
        print(f'[SMS-LAMBDA-V5] JSON Parse Error: {str(e)}')
        return error_response(
            400, 
            'INVALID_JSON', 
            f'Invalid JSON in request body: {str(e)}',
            'Ensure request body is valid JSON',
            None, 
            request_id
        )
        
    except Exception as e:
        print(f'[SMS-LAMBDA-V5] Unexpected Error: {str(e)}')
        import traceback
        traceback.print_exc()
        return error_response(
            500, 
            'INTERNAL_ERROR', 
            f'Internal server error: {str(e)}',
            'Contact system administrator',
            None, 
            request_id
        )


def error_response(status_code, error_code, error_message, remediation, phone_number, request_id, message_id=None):
    """
    Return error response with CORS headers and remediation steps
    CRITICAL: Never return HTTP 200 for errors
    
    Args:
        status_code: HTTP status code (400, 502, 500, etc.)
        error_code: Machine-readable error code (e.g., "COUNTRY_NOT_SUPPORTED")
        error_message: Human-readable error message
        remediation: Actionable steps to fix the issue
        phone_number: Phone number (for masking)
        request_id: AWS request ID
        message_id: SNS MessageId (if available)
    """
    response_body = {
        'ok': False,  # Always false for errors
        'provider': 'sns',
        'errorCode': error_code,
        'errorMessage': error_message,
        'remediation': remediation,
        'toMasked': mask_phone(phone_number) if phone_number else 'N/A',
        'requestId': request_id,
        'timestamp': datetime.utcnow().isoformat() + 'Z'
    }
    
    # Include MessageId if available (for traceability)
    if message_id:
        response_body['messageId'] = message_id
    
    return {
        'statusCode': status_code,  # Must be non-200 for errors
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': 'https://dfc8ght8abwqc.cloudfront.net',
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'content-type'
        },
        'body': json.dumps(response_body)
    }


def mask_phone(phone):
    """Mask phone number for privacy (e.g., +1234567890 -> +1***7890)"""
    if not phone:
        return 'N/A'
    if len(phone) > 6:
        return phone[:3] + '***' + phone[-4:]
    return phone
